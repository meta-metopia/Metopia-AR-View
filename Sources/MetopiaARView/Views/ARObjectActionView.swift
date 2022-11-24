//
//  ARObjectActionView.swift
//  metopia
//
//  Created by Qiwei Li on 9/20/22.
//

import MetopiaARCreatorCommon
import SwiftUI

/// Render view based ob the ``ARObjectType``
struct ARObjectActionView: View {
  let uiViewModel: any UIViewModelProtocol
  let model: ModelWithEntity
  
  init(model: ModelWithEntity, uiViewModel: any UIViewModelProtocol) {
    self.uiViewModel = uiViewModel
    self.model = model
  }



  var body: some View {
    NavigationView {
      render()
        .navigationTitle("\(model.name)")
        .navigationBarTitleDisplayMode(.inline)
        .interactiveDismissDisabled()
        .toolbar {
          ToolbarItem(placement: .cancellationAction) {
            Button("Close") {
              uiViewModel.dismiss()
            }
          }
        }
    }
  }

  private func render() -> AnyView {
    switch model.objectType {
    case .link:
      return AnyView(ARObjectLinkActionView(model: model))
    default:
      return AnyView(Text("\(model.objectType.rawValue.capitalized) Not support yet"))
    }
  }
}
