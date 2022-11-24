//
//  ARView+Extension.swift
//  metopia
//
//  Created by Qiwei Li on 8/12/22.
//

import ARKit
import Foundation
import RealityKit

//MARK: Setup ARView
extension ARView {
  static func configuration() -> ARWorldTrackingConfiguration {
    let configuration = ARWorldTrackingConfiguration()
    configuration.environmentTexturing = .automatic

    if ARWorldTrackingConfiguration.supportsFrameSemantics(.personSegmentationWithDepth) {
      configuration.frameSemantics.insert(.personSegmentationWithDepth)
    }

    if ARWorldTrackingConfiguration.supportsSceneReconstruction(.meshWithClassification) {
      configuration.sceneReconstruction = .meshWithClassification
    }

    if ARWorldTrackingConfiguration.supportsFrameSemantics(.smoothedSceneDepth) {
      configuration.frameSemantics.insert(.sceneDepth)
    }

//    if #available(iOS 16.0, *) {
//      if let hiResFormat = ARWorldTrackingConfiguration.recommendedVideoFormatFor4KResolution {
//        configuration.videoFormat = hiResFormat
//        logger.info("Using 4k resolution")
//      }
//    }

    /**
         When enable this line, loading model will not work
         */
    configuration.planeDetection = [.horizontal, .vertical]
    return configuration
  }

  static func getDebugOptions() -> [DebugOptions] {
    return [.showStatistics, .showSceneUnderstanding, .showWorldOrigin, .showFeaturePoints]
  }

  /**
     Get center worldtransform from raycast
     */
  func center() -> simd_float4x4? {
    guard
      let query = self.makeRaycastQuery(
        from: self.center, allowing: .estimatedPlane, alignment: .any)
    else {
      return nil
    }

    guard let result = self.session.raycast(query).first else { return nil }
    return result.worldTransform
  }

  static var worldMap: URL {
    try! FileManager.default.url(
      for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true
    )
    .appendingPathComponent("worldmap")
  }

}

//MARK: Initialize coaching view
extension ARView: ARCoachingOverlayViewDelegate {
  func addCoaching() {
    let coachingOverlay = ARCoachingOverlayView()
    coachingOverlay.activatesAutomatically = true
    coachingOverlay.delegate = self
    #if !targetEnvironment(simulator)
      coachingOverlay.session = self.session
    #endif
    coachingOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    coachingOverlay.goal = .anyPlane
    self.addSubview(coachingOverlay)
  }

  public func coachingOverlayViewDidDeactivate(_ coachingOverlayView: ARCoachingOverlayView) {
    logger.info("Coaching overlay deactivate")
  }
}
