//
//  CustomARView.swift
//  metopia
//
//  Created by Qiwei Li on 9/20/22.
//

import ARKit
import Foundation
import RealityFoundation
import SwiftUI
import MetopiaARCreatorCommon
import FocusEntity
import RealityKit

public class FocusARView: ARView {
  var focusEntity: FocusEntity?
  required init(frame frameRect: CGRect, showFocus: Bool) {
    super.init(frame: frameRect)
    if showFocus {
      self.focusEntity = FocusEntity(on: self, focus: .classic)
    }
  }

  @objc required dynamic init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  @MainActor required dynamic init(frame frameRect: CGRect) {
    fatalError("init(frame:) has not been implemented")
  }
}


public class CustomARView: FocusARView {
  private var arViewModel: any ARViewModelProtocol
  private var uiViewModel: any UIViewModelProtocol
  private let showFocus: Bool

  required init(
    frame frameRect: CGRect, showFocus: Bool, arViewModel: any ARViewModelProtocol,
    uiViewModel: any UIViewModelProtocol
  ) {
    self.arViewModel = arViewModel
    self.uiViewModel = uiViewModel
    self.showFocus = showFocus
    super.init(frame: frameRect, showFocus: showFocus)
  }

  @objc required dynamic init?(coder decoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  required init(frame frameRect: CGRect) {
    fatalError("init(frame:) has not been implemented")
  }

  required init(frame frameRect: CGRect, showFocus: Bool) {
    fatalError("init(frame:showFocus:) has not been implemented")
  }

}

//MARK: Initialize saved anchors
extension CustomARView {
  /**
   Remove all anchors from ARView except focus entities (first two)
   */
  func removePreviosAnchors() {
    logger.info("Anchor count \(self.scene.anchors.count)")
    if showFocus {
      let box = self.scene.anchors[0]
      let focusEntity = self.scene.anchors[1]

      let size = self.scene.anchors.count
      if size == 2 {
        return
      }
      self.scene.anchors.removeAll()
      self.scene.anchors.append(box)
      self.scene.anchors.append(focusEntity)
    } else {
      self.scene.anchors.removeAll()
    }

  }

  func placeObject(at anchor: ARAnchor, with model: ModelWithEntity) {
    #if !targetEnvironment(simulator)
      let anchorEntity = AnchorEntity(anchor: anchor)
      guard let entity = model.entity else {
        return
      }

      let parentEntity = ModelEntity()
      let clonedEntity = entity.clone(recursive: true)
      parentEntity.name = anchor.name ?? ""

      parentEntity.addChild(clonedEntity)
      let entityBounds = entity.visualBounds(relativeTo: parentEntity)
      parentEntity.collision = CollisionComponent(shapes: [
        ShapeResource.generateBox(size: entityBounds.extents).offsetBy(
          translation: entityBounds.center)
      ])

      self.installGestures([.scale, .rotation], for: parentEntity)

      anchorEntity.addChild(parentEntity)
      self.scene.addAnchor(anchorEntity)
    #endif

  }
}

//MARK: Enable on touch gesture
extension CustomARView {
  /**
   Enable gestures for models
   */
  func enableOnTapGesture() {
    let onTapGesture = UITapGestureRecognizer(target: self, action: #selector(onTap(recognizer:)))
    self.addGestureRecognizer(onTapGesture)
  }

  @objc func onTap(recognizer: UITapGestureRecognizer) {
    logger.info("OnTap gesture triggered")
    let location = recognizer.location(in: self)
    if let entity = self.entity(at: location) as? ModelEntity {
      logger.info("\(entity.name)")
      if let model = self.arViewModel.usedModels.first(where: { m in
        String(m.id) == Model.Without(prefixOf: entity.name)
      }) {
        logger.info("presenting a ar object action view")
        if model.objectType == .none {
          return
        }
        self.uiViewModel.present(ARObjectActionView(model: model, uiViewModel: self.uiViewModel))
      }
    }
  }
}

//MARK: Enable long press deletion gesture
extension CustomARView {
  func enableDeletion() {
    let longPressGesture = UILongPressGestureRecognizer(
      target: self, action: #selector(onLongPress(recognizer:)))
    self.addGestureRecognizer(longPressGesture)
  }

  @objc func onLongPress(recognizer: UITapGestureRecognizer) {
    let location = recognizer.location(in: self)
    if let entity = self.entity(at: location) as? ModelEntity {
      logger.info("Entering deletion mode for \(entity.id)")
      self.arViewModel.selectedModelForDeletion = entity
    }
  }
}
