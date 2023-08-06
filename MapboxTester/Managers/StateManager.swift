//
//  StateManager.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import CoreLocation

// TODO: Convert to Combine if you're smarter than I am.
protocol StateListener {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State)
}

final class StateManager {
  struct RouteRequest {
    let start: CLLocationCoordinate2D
    let end: CLLocationCoordinate2D
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
        $0.didUpdate(from: oldValue, to: state)
      }
    }
  }

  // MARK: -- Listeners

  private var listeners: [StateListener] = []

  func add(listener: StateListener) {
    listeners.append(listener)
  }
}
