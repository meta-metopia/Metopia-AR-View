//
//  ModelAnchor.swift
//  
//
//  Created by Qiwei Li on 11/24/22.
//

import Foundation
import ARKit
import MetopiaARCreatorCommon

public struct ModelAnchor {
  public var anchor: ARAnchor
  public var model: ModelWithEntity
  
  public init(anchor: ARAnchor, model: ModelWithEntity) {
    self.anchor = anchor
    self.model = model
  }
}
