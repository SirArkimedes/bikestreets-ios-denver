//
//  MapCameraManager.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/28/23.
//

import Foundation
import MapboxDirections

// TODO: Convert to Combine if you're smarter than I am.
protocol MapCameraStateListener: AnyObject {
  func didUpdate(from oldState: MapCameraManager.State, to newState: MapCameraManager.State)
}

final class MapCameraManager {
  enum State {
    /// Centered on the user, no relation to direction of travel.
    case followUserPosition
    case followUserPositionIdle
    /// Centered on the user, map orientation following direction of travel.
    case followUserHeading
    case followUserHeadingIdle
    /// Not oriented to anything. User could be free-scrolling the map.
    case showRoute(route: Route)
    case showRouteIdle(route: Route)
  }

  var state: State = .followUserPosition {
    didSet {
      listeners.forEach {
        $0.value?.didUpdate(from: oldValue, to: state)
      }

      // Clean up listeners
      listeners.reap()
    }
  }

  /// SF Symbols name to use based on the current state.
  var imageSystemName: String {
    switch state {
    case .followUserPosition:
      return "location.fill"
    case .followUserPositionIdle:
      return "location"
    case .followUserHeading:
      return "location.north.line.fill"
    case .followUserHeadingIdle:
      return "location.north.line"
    case .showRoute:
      return "location.fill.viewfinder"
    case .showRouteIdle:
      return "location.viewfinder"
    }
  }

  // MARK: -- Listeners

  private var listeners: [Weak] = []

  func add(listener: MapCameraStateListener) {
    listeners.append(Weak(value: listener))
  }

  // MARK: -- Actions

  /// Transition from current state to idle state of the same type.
  func toIdle() {
    switch state {
    case .followUserPosition:
      state = .followUserPositionIdle
    case .followUserHeading:
      state = .followUserHeadingIdle
    case .showRoute(let route):
      state = .showRouteIdle(route: route)
    case .followUserPositionIdle,
        .followUserHeadingIdle,
        .showRouteIdle:
      // Already idle
      break
    }
  }

  /// Transition from current state to non-idle state of the same type.
  func fromIdle() {
    switch state {
    case .followUserPositionIdle:
      state = .followUserPosition
    case .followUserHeadingIdle:
      state = .followUserHeading
    case .showRouteIdle(let route):
      state = .showRoute(route: route)
    case .followUserPosition,
        .followUserHeading,
        .showRoute:
      // Already not idle
      break
    }
  }
}

// MARK: -- Weak Handling

private class Weak {
  weak var value : MapCameraStateListener?
  init (value: MapCameraStateListener) {
    self.value = value
  }
}

private extension Array where Element: Weak {
  mutating func reap () {
    self = self.filter { nil != $0.value }
  }
}
