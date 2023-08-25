//
//  ScreenManager.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/6/23.
//

import Foundation
import UIKit

/// Implementation that keeps the screen on while routing.
final class ScreenManager {
  init(stateManager: StateManager) {
    stateManager.add(listener: self)
  }
}

extension ScreenManager: StateListener {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State) {
    switch oldState {
    case .routing:
      UIApplication.shared.isIdleTimerDisabled = false
    default: break
    }

    switch newState {
    case .routing:
      UIApplication.shared.isIdleTimerDisabled = true
    default: break
    }
  }
}
