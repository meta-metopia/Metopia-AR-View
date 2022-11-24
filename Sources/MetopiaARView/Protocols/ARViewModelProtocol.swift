//
//  ARViewModelProtocol.swift
//  metopia
//
//  Created by Qiwei Li on 11/23/22.
//

import Foundation
import MetopiaARCreatorCommon
import RealityKit

public protocol ARViewModelProtocol: ObservableObject {
  var selectedModelForAddition: ModelWithEntity? { get set }
  var selectedModelForDeletion: ModelEntity? { get set }
  var usedModels: [ModelWithEntity] { get set }
  var currentWorldMap: WorldMapWithARWorldMap? { get set }
}
