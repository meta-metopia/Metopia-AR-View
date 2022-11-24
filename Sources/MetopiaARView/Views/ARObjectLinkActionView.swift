//
//  ARObjectLinkActionView.swift
//  metopia
//
//  Created by Qiwei Li on 9/20/22.
//

import MetopiaARCreatorCommon
import SwiftUI
import WebViewKit

struct ARObjectLinkActionView: View {
  let model: ModelWithEntity

  var body: some View {
    if let url = URL(string: model.content ?? "") {
      WebView(url: url)
    } else {
      Text("URL \(model.content ?? "") is not a valid url")
    }
  }
}
