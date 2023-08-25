//
//  StateManager.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import CoreLocation
import MapKit

// TODO: Convert to Combine if you're smarter than I am.
protocol StateListener: AnyObject {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State)
}

final class StateManager {
  struct RouteRequest {
    enum Location {
      case currentLocation(coordinate: CLLocationCoordinate2D)
      case mapLocation(item: MKMapItem)

      // MARK: -- Helpers

      var name: String {
        switch self {
        case .currentLocation:
          return "Current Location"
        case .mapLocation(let item):
          return item.name ?? "No Name"
        }
      }

      var coordinate: CLLocationCoordinate2D {
        switch self {
        case .currentLocation(let coordinate):
          return coordinate
        case .mapLocation(let item):
          return item.placemark.coordinate
        }
      }
    }

    let origin: Location
    let destination: Location
  }

  struct DirectionsPreview {
    let request: RouteRequest
    let response: RouteServiceResponse
    let selectedRoute: Route
  }

  struct Routing {
    let request: RouteRequest
    let response: RouteServiceResponse
    let selectedRoute: Route
  }

  enum State {
    case initial
    case requestingRoutes(request: RouteRequest)
    case previewDirections(preview: DirectionsPreview)
    case routing(routing: Routing)
  }

  var state: State = .initial {
    didSet {
      listeners.forEach {
        $0.value?.didUpdate(from: oldValue, to: state)
      }

      // Clean up listeners
      listeners.reap()
    }
  }

  // MARK: -- Listeners

  private var listeners: [Weak] = []

  func add(listener: StateListener) {
    listeners.append(Weak(value: listener))
  }
}

// MARK: -- Weak Handling

private class Weak {
  weak var value : StateListener?
  init (value: StateListener) {
    self.value = value
  }
}

private extension Array where Element: Weak {
  mutating func reap () {
    self = self.filter { nil != $0.value }
  }
}
