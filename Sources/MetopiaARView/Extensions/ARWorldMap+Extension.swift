//
//  ARWorldMap+Extension.swift
//  metopia
//
//  Created by Qiwei Li on 8/12/22.
//

import ARKit
import Foundation

extension ARWorldMap {

  /**
     Get descriptive message for world map object
     */
  var subtitle: String {
    "Feature points: \(rawFeaturePoints.points.count), Anchors: \(anchors.count)"
  }
}
