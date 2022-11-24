//
//  UIViewModelProtocol.swift
//  metopia
//
//  Created by Qiwei Li on 11/23/22.
//

import Foundation
import SwiftUI

public protocol UIViewModelProtocol: ObservableObject {
  func notify(title: String, subtitle: String)
  func present<Sheet: View>(_ sheet: @autoclosure @escaping () -> Sheet)
  func dismiss()
}
