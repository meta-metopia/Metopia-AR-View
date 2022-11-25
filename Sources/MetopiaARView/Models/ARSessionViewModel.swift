//
//  ARViewController.swift
//  metopia
//
//  Created by Qiwei Li on 10/13/22.
//

import ARCore
import ARKit
import Foundation
import MetopiaARCreatorCommon
import RealityKit

public typealias OnPreSave = (ARWorldMap, [ARAnchor]) -> Void
/// Pre-Save map
public typealias PreSave = () -> Void
/// When calling save function,  will call arcore function to host anchors
public typealias Save = ([ARAnchor]) -> Void
/// Load existing map
public typealias Load = (ARWorldMap?, [CloudARAnchor]?, PositioningEngineType) -> Void
/// Add new model to the scene
public typealias AddModel = ((ModelWithEntity) -> Void)
/// This function will be called by ARSessionDelegate
public typealias OnPlaceModel = ((ModelAnchor) -> Void)
/// Enable debug session
public typealias ToggleDebugSession = (Bool) -> Void

public typealias OnDelete = (String) -> Void

public typealias OnAnchorResolved = (ARAnchor, String) -> Void

public typealias OnImageCapture = () async throws -> UIImage

public class ARSessionViewModel: ObservableObject {
  //    @Published var resolveAnchors: ResolveAnchors!
  @Published public var placeModel: OnPlaceModel!
  @Published public var addModel: AddModel!
  @Published public var preSave: PreSave!
  @Published public var load: Load!
  @Published public var toggleDebugSession: ToggleDebugSession!
  @Published public var onDelete: OnDelete!
  @Published public var save: Save!
  @Published public var onAnchorResolved: OnAnchorResolved!
  @Published public var onImageCapture: OnImageCapture!
  @Published public var arState: ARCamera.TrackingState = .notAvailable {
    didSet {
      switch arState {
      case .normal:
        isShowingLoading = false
      default:
        isShowingLoading = true
      }
    }
  }
  @Published public var isShowingLoading = true

  @Published public var gSession: GARSession?

  @Published public var loadedCloudAnchors: [CloudARAnchor] = []

  @Published public var pendingToBeUploadedAnchors: [CloudARAnchor] = []
  
  public init(key: String) {
    self.gSession = try? GARSession(apiKey: key, bundleIdentifier: nil)
  }

  public var hostingAnchorsTitle: String {
    let numUploaded = pendingToBeUploadedAnchors.filter { anchor in
      anchor.hasUploaded
    }.count

    if numUploaded == pendingToBeUploadedAnchors.count {
      return "Anchors are hosted"
    }

    return "Hosting anchors \(numUploaded)/\(pendingToBeUploadedAnchors.count)"
  }

  public var progress: Double {
    let numUploaded = pendingToBeUploadedAnchors.filter { anchor in
      anchor.hasUploaded
    }.count

    let total = pendingToBeUploadedAnchors.count

    if total == 0 {
      return 1
    }
    return Double(numUploaded) / Double(total)
  }

  public func waitForAllAnchorsAreHosted() async {
    while true {
      var hasFinished = true
      for anchor in self.pendingToBeUploadedAnchors {
        if !anchor.hasUploaded {
          hasFinished = false
          break
        }
      }
      if hasFinished {
        break
      }

      try! await Task.sleep(nanoseconds: 1_000_000_000)
    }
  }

  public func dismiss() {
    pendingToBeUploadedAnchors.removeAll()
  }

  public func onAnchorHostedHandler(anchor: CloudARAnchor, index: Int) {
    self.pendingToBeUploadedAnchors[index] = anchor
  }
}
