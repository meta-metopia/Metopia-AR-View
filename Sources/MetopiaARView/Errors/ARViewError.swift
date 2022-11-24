//
//  Errors.swift
//  metopia
//
//  Created by Qiwei Li on 11/22/22.
//

import Foundation

struct ARViewError: LocalizedError {
  var title: String?
  var code: Int
  var errorDescription: String? { return _description }
  var failureReason: String? { return _description }

  private var _description: String

  init(title: String?, description: String, code: Int) {
    self.title = title ?? "Error"
    self._description = description
    self.code = code
  }
}
