//
//  Models.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import CoreLocation
import Foundation

struct Waypoint: Decodable {
  let name: String
  let location: [Float]
  let distance: Float
  let hint: String
}

struct Route: Decodable, Equatable {
  struct Geometry: Decodable, Equatable {
    private enum CodingKeys: String, CodingKey {
      case type
      case _coordinates = "coordinates"
    }

    let type: String
    let _coordinates: [[Double]]

    var coordinates: [CLLocationCoordinate2D] {
      _coordinates.map { coordinates in
        CLLocationCoordinate2D(latitude: coordinates[1], longitude: coordinates[0])
      }
    }
  }

  let distance: Double
  let duration: Double
  let geometry: Geometry
  //  let legs: [RouteLeg]
}

struct RouteServiceResponse: Decodable {
  let code: String
  let waypoints: [Waypoint]
  let routes: [Route]
}
