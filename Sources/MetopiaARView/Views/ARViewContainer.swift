//
//  ARViewContainer.swift
//  metopia
//
//  Created by Qiwei Li on 8/12/22.
//

import ARCore
import ARKit
import RealityKit
import SwiftUI
import MetopiaARCreatorCommon

public typealias UIViewType = CustomARView

public struct ARViewContainer: UIViewRepresentable {
 
  let arViewModel: any ARViewModelProtocol
  let uiViewModel: any UIViewModelProtocol
  @EnvironmentObject var arSessionViewModel: ARSessionViewModel

  let isCreationMode: Bool
  let settings: [ARSettings]
  let onPreSave: OnPreSave

  /**
   Create a ar view for swift ui
   - parameter onSave: Callback function whenever model has been saved
   - parameter settings: List of ar settings.
   - parameter isCreationMode: Boolean value indicates whether the AR View is in the creation mode. If false, some functionalities will be disabled.
   */
  public init(
    isCreationMode: Bool = true, uiViewModel: any UIViewModelProtocol,
    arViewModel: any ARViewModelProtocol,settings: [ARSettings] = [] ,onPreSave: @escaping OnPreSave
  ) {
    self.onPreSave = onPreSave
    self.isCreationMode = isCreationMode
    self.uiViewModel = uiViewModel
    self.arViewModel = arViewModel
    self.settings = settings
  }

  public func makeUIView(context: Context) -> CustomARView {
    logger.info("initialized ar view")
    let view = CustomARView(
      frame: .zero, showFocus: isCreationMode, arViewModel: arViewModel, uiViewModel: uiViewModel)

    let arCoreConfiguration = GARSessionConfiguration()
    arCoreConfiguration.cloudAnchorMode = .enabled
    arSessionViewModel.gSession?.setConfiguration(arCoreConfiguration, error: nil)

    view.enableDeletion()
    view.enableOnTapGesture()
    view.addCoaching()
    
    view.session.delegate = context.coordinator
    arSessionViewModel.gSession?.delegate = context.coordinator
    
    view.configView(using: settings)
    
    DispatchQueue.main.async {
      arSessionViewModel.addModel = { model in
        onAddHandler(on: view, using: model)
      }

      arSessionViewModel.placeModel = { model in
        onPlaceHandler(on: view, using: model)
      }

      arSessionViewModel.load = { map, cloudAnchors, positioningEngine in
        onLoadHandler(
          on: view, using: map, with: cloudAnchors, positioningEngine: positioningEngine)
      }

      arSessionViewModel.onDelete = { anchor in
        Task {
          await onDeleteHandler(on: view, using: anchor)
        }
      }

      arSessionViewModel.preSave = {
        Task {
          await onPreSaveHandler(on: view)
        }
      }

      arSessionViewModel.save = { anchors in
        onSaveHandler(on: view, using: anchors)
      }

      arSessionViewModel.onAnchorResolved = { anchor, hostedId in
        onAnchorResolvedHandler(on: view, using: anchor, with: hostedId)
      }

      arSessionViewModel.onImageCapture = {
        return try await withCheckedThrowingContinuation { cont in
          view.snapshot(saveToHDR: false) { image in
            if let image = image {
              cont.resume(returning: image)
            } else {
              cont.resume(
                throwing: ARViewError(title: "Unable to capture image", description: "", code: 1))
            }
          }
        }
      }

    }

    return view
  }

  public func updateUIView(_ uiView: CustomARView, context: Context) {
    uiView.configView(using: settings)
  }
}

//MARK: handlers
extension ARViewContainer {
  func onDeleteHandler(on view: CustomARView, using anchorName: String) async {
    let map = try? await view.session.currentWorldMap()
    guard let map = map else {
      return
    }

    let anchor = map.anchors.first { a in
      a.name == anchorName
    }

    if let anchor = anchor {
      logger.info("Deleting found anchor: \(anchor)")
      view.session.remove(anchor: anchor)
    }
  }

  func onAddHandler(on view: CustomARView, using model: ModelWithEntity) {
    logger.info("Adding model \(model.id)")
    guard let center = view.center() else {
      uiViewModel.notify(title: "Cannot place model at this position", subtitle: "Center is nil")
      return
    }
    let anchor = ARAnchor(name: "\(ANCHOR_PREFIX)\(model.id)", transform: center)
    view.session.add(anchor: anchor)
    self.arViewModel.usedModels.append(model)
  }

  func onPlaceHandler(on view: CustomARView, using modelAnchor: ModelAnchor) {
    view.placeObject(at: modelAnchor.anchor, with: modelAnchor.model)
  }

  @MainActor
  func onPreSaveHandler(on view: CustomARView) async {
    guard let map = try? await view.session.currentWorldMap() else {
      uiViewModel.notify(title: "Cannot save", subtitle: "Unable to get world map")
      return
    }

    var anchors: [ARAnchor] = []
    var cloudAnchors: [CloudARAnchor] = []

    for anchor in map.anchors {
      let (_, modelName) = Model.isModel(from: anchor)
      if let _ = modelName {
        let cloudAnchor = CloudARAnchor(
          id: anchor.identifier, hostId: nil, modelName: anchor.name!, hasError: false, time: Date()
        )
        logger.info("Hosting cloud anchor \(cloudAnchor.id)")
        anchors.append(anchor)
        cloudAnchors.append(cloudAnchor)
      }
    }

    try! self.writeWorldMap(map, to: ARView.worldMap)
    arSessionViewModel.pendingToBeUploadedAnchors = cloudAnchors
    self.onPreSave(map, anchors)
  }

  func onLoadHandler(
    on view: CustomARView, using worldMap: ARWorldMap?, with cloudAnchors: [CloudARAnchor]?,
    positioningEngine: PositioningEngineType
  ) {
    view.removePreviosAnchors()
    switch positioningEngine {
      case .defaultEngine:
        guard let map = arViewModel.currentWorldMap?.map else {
          uiViewModel.notify(title: "Cannot load world map", subtitle: "Map is nil")
          return
        }
        logger.info("Using worldmap")
        view.configView(using: settings, map: map)
        uiViewModel.notify(title: "Map is loaded", subtitle: map.subtitle)
        return
      case .cloudAnchor:
        uiViewModel.notify(
          title: "Using cloud anchor", subtitle: "Number of anchors: \(cloudAnchors?.count ?? 0)")
        if let cloudAnchors = cloudAnchors {
          self.arSessionViewModel.loadedCloudAnchors = cloudAnchors
          view.configView(using: settings)
          let anchorsWithIds = cloudAnchors.filter { anchor in
            anchor.hostId != nil
          }
          for anchor in anchorsWithIds {
            _ = try! self.arSessionViewModel.gSession?.resolveCloudAnchor(anchor.hostId!)
            logger.info("Resolving cloud anchor \(anchor.hostId!)")
          }
        }
        return
      default:
        uiViewModel.notify(title: "Positioning Engine not support yet", subtitle: "Given engine \(positioningEngine)")
    }

  }

  func onSaveHandler(on view: CustomARView, using anchors: [ARAnchor]) {
    var index = 0
    for anchor in anchors {
      let hostedAnchor = try! arSessionViewModel.gSession?.hostCloudAnchor(anchor)
      arSessionViewModel.pendingToBeUploadedAnchors[index].id = hostedAnchor!.identifier
      index += 1
    }
  }

  private func onAnchorResolvedHandler(
    on view: CustomARView, using anchor: ARAnchor, with hostedId: String
  ) {
    if let foundedModel = arSessionViewModel.loadedCloudAnchors.first(where: { cloudAnchor in
      cloudAnchor.hostId == hostedId
    }) {
      let newAnchor = ARAnchor(name: foundedModel.modelName, transform: anchor.transform)
      view.session.add(anchor: newAnchor)
      uiViewModel.notify(title: "Found hosted anchor", subtitle: foundedModel.modelName)
    }
  }

  private func writeWorldMap(_ worldMap: ARWorldMap, to url: URL) throws {
    let data = try NSKeyedArchiver.archivedData(
      withRootObject: worldMap, requiringSecureCoding: true)
    try data.write(to: url)
  }

}

extension ARViewContainer {
  public class Coordinator: NSObject, ARSessionDelegate, GARSessionDelegate {
    var parent: ARViewContainer

    init(parent: ARViewContainer) {
      self.parent = parent
    }

    public func session(_ session: ARSession, didUpdate frame: ARFrame) {
      do {
        try parent.arSessionViewModel.gSession?.update(frame)
      } catch {
        logger.error("error \(error)")
      }
    }

    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
      parent.arSessionViewModel.arState = camera.trackingState
    }

    public func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
      for anchor in anchors {

        let (_, modelId) = Model.isModel(from: anchor)

        guard let modelId = modelId else {
          continue
        }

        if let model = parent.arViewModel.usedModels.first(where: { m in
          String(m.id) == modelId
        }) {
          self.parent.arSessionViewModel.placeModel(ModelAnchor(anchor: anchor, model: model))
        }
      }
    }

    public func session(_ session: GARSession, didHost anchor: GARAnchor) {
      let id = anchor.cloudIdentifier
      logger.info("Did host anchor \(anchor.identifier)")
      let pendingAnchorIndex = self.parent.arSessionViewModel.pendingToBeUploadedAnchors.firstIndex
      {
        a in
        a.id == anchor.identifier
      }

      if let pendingAnchorIndex = pendingAnchorIndex {
        var anchor = self.parent.arSessionViewModel.pendingToBeUploadedAnchors[pendingAnchorIndex]
        anchor.hostId = id
        self.parent.arSessionViewModel.onAnchorHostedHandler(
          anchor: anchor, index: pendingAnchorIndex)
      }

    }

    public func session(_ session: GARSession, didFailToHost anchor: GARAnchor) {
      logger.error("Failed to add cloud anchor")
      let pendingAnchorIndex = self.parent.arSessionViewModel.pendingToBeUploadedAnchors.firstIndex
      {
        a in
        a.id == anchor.identifier
      }

      if let pendingAnchorIndex = pendingAnchorIndex {
        var anchor = self.parent.arSessionViewModel.pendingToBeUploadedAnchors[pendingAnchorIndex]
        anchor.hasError = true
        self.parent.arSessionViewModel.onAnchorHostedHandler(
          anchor: anchor, index: pendingAnchorIndex)
      }

    }

    public func session(_ session: GARSession, didFailToResolve anchor: GARAnchor) {
      logger.error("Failed to resolve anchor \(anchor.cloudIdentifier ?? "")")
    }

    public func session(_ session: GARSession, didResolve anchor: GARAnchor) {
      logger.info("Resovled anchor \(anchor.cloudIdentifier!)")
      let arAnchor = ARAnchor(transform: anchor.transform)
      self.parent.arSessionViewModel.onAnchorResolved(arAnchor, anchor.cloudIdentifier!)
    }
  }

  public func makeCoordinator() -> Coordinator {
    return Coordinator(parent: self)
  }
}
