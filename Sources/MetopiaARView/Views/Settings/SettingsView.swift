//
//  SwiftUIView.swift
//  
//
//  Created by Qiwei Li on 11/28/22.
//

import SwiftUI
import MetopiaARCreatorCommon

public typealias OnSettingsSave = ([ARSettings]) async -> ()

struct UserSelectedSetting: Identifiable, Equatable {
  let id = UUID()
  var setting: ARSettings
  var isSelected: Bool
}

public struct SettingsView: View {
  @State var settings: [UserSelectedSetting]
  let onSave: OnSettingsSave
  
  /**
   Initialize settings view without default settings
   */
  init(onSave: @escaping OnSettingsSave) {
    let defaultSettings = ARSettings.allCases.map { setting in
      UserSelectedSetting(setting: setting, isSelected: false)
    }
    _settings = .init(initialValue: defaultSettings)
    self.onSave = onSave
  }
  
  /**
   Initialize settings view using default settings
   - parameter settings: Default settings
   */
  init(settings: [ARSettings], onSave: @escaping OnSettingsSave) {
    let defaultSettings = ARSettings.allCases.map { setting in
      UserSelectedSetting(setting: setting, isSelected: settings.contains(setting))
    }
    _settings = .init(initialValue: defaultSettings)
    self.onSave = onSave
  }
  
  var body: some View {
    Form {
      Section("AR settings") {
        ForEach($settings) { (setting: Binding<UserSelectedSetting>) in
          Toggle(isOn: setting.isSelected) {
            HStack {
              Image(systemName: setting.wrappedValue.setting.icon)
              Text("\(setting.wrappedValue.setting.rawValue)")
            }
          }
        }
      }
    }.onChange(of: settings) { setting in
      let settings: [ARSettings] = settings.filter { setting in
        setting.isSelected
      }.map { setting in
        setting.setting
      }
      
      Task {
        await onSave(settings)
      }
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
  static var previews: some View {
    SettingsView() { settings in
      
    }
  }
}
