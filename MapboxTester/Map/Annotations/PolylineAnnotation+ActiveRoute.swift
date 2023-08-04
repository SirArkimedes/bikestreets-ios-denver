//
//  PolylineAnnotation+ActiveRoute.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import MapboxMaps

extension PolylineAnnotation {
  static func activeRouteAnnotation(coordinates: [CLLocationCoordinate2D]) -> PolylineAnnotation {
    var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)
    polylineAnnotationOSM.lineColor = .init(.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8))
    polylineAnnotationOSM.lineWidth = 4
    return polylineAnnotationOSM
  }

  static func potentialRouteAnnotation(coordinates: [CLLocationCoordinate2D]) -> PolylineAnnotation {
    var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)
    polylineAnnotationOSM.lineColor = .init(.init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5))
    polylineAnnotationOSM.lineWidth = 4
    return polylineAnnotationOSM
  }
}
