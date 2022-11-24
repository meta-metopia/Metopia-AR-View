//
//  ARViewProtocol.swift
//  metopia
//
//  Created by Qiwei Li on 11/22/22.
//

import Foundation
import SwiftUI

public protocol MetopiaARViewProtocol: View {
  func loadModels() async
  
  func loadMap() async
}
