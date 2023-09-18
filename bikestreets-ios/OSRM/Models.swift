//
//  Models.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import CoreLocation
import Foundation

struct RouteServiceResponse: Codable {
  let code: String
  let waypoints: [Waypoint]
  let routes: [Route]
}

// MARK: - OSRM Models

struct Geometry: Codable, Equatable {
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

/// http://project-osrm.org/docs/v5.5.1/api/#route-object
struct Route: Codable, Equatable {
  let distance: Double
  let duration: Double
  let geometry: Geometry
  let legs: [RouteLeg]
}

/// http://project-osrm.org/docs/v5.5.1/api/#routeleg-object
struct RouteLeg: Codable, Equatable {
  let distance: Double
  let duration: Double
  let summary: String
  let steps: [RouteStep]
  // let annotation: [Annotation]
}

/// http://project-osrm.org/docs/v5.5.1/api/#routestep-object
struct RouteStep: Codable, Equatable {
  enum Mode: String, Codable, Equatable {
    case cycling
    case pushingBike = "pushing bike"
  }

  let distance: Double
  let duration: Double
  let geometry: Geometry
  let name: String
  // ref
  // pronunciation
  // destinations

  // cycling
  // pushing bike
  let mode: Mode

  // let maneuver: StepManeuver

  // let intersections: [Intersection]
}

/// http://project-osrm.org/docs/v5.5.1/api/#annotation-object
//struct Annotation: Decodable, Equatable {
//  let distance: Double
//  let duration: Double
//
//  // datasources
//  // nodes
//}

/// http://project-osrm.org/docs/v5.5.1/api/#stepmaneuver-object
//struct StepManeuver: Decodable, Equatable {
//  // location
//  // bearing_before
//  // bearing_after
//  // type
//  // modifier
//  // exit
//}

/// http://project-osrm.org/docs/v5.5.1/api/#lane-object
//struct Lane: Decodable, Equatable {
//  // indications
//  // valid
//}

/// http://project-osrm.org/docs/v5.5.1/api/#intersection-object
//struct Intersection: Decodable, Equatable {
//  // location
//  // bearings
//  // entry
//  // in
//  // out
//  // lanes
//}

/// http://project-osrm.org/docs/v5.5.1/api/#waypoint-object
struct Waypoint: Codable {
  let name: String
  let location: [Float]
  let distance: Float
  let hint: String
}
