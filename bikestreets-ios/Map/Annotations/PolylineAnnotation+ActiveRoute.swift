//
//  PolylineAnnotation+ActiveRoute.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import MapboxMaps

private extension UIColor {
  // Before: .init(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.5)
  static let inactiveRouteColor: UIColor = .init(red: 68/255.0, green: 119/255, blue: 242/255, alpha: 0.4)
}

extension PolylineAnnotation {
  static func activeRouteAnnotation(
    coordinates: [CLLocationCoordinate2D],
    isRouting: Bool,
    isHikeABike: Bool
  ) -> PolylineAnnotation {
    var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)

    // For now, apply a 65% alpha to enable the BikeStreets network to be shown beneath it.
    let color: UIColor = { () -> UIColor in
      let startingColor: UIColor
      if isHikeABike {
        startingColor = .vamosPurple
      } else {
        startingColor = .vamosBlue
      }

      return isRouting ? startingColor : startingColor.withAlphaComponent(0.65)
    }()

    polylineAnnotationOSM.lineColor = .init(color)
    polylineAnnotationOSM.lineWidth = 6
    return polylineAnnotationOSM
  }

  static func potentialRouteAnnotation(coordinates: [CLLocationCoordinate2D]) -> PolylineAnnotation {
    var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)
    polylineAnnotationOSM.lineColor = .init(.inactiveRouteColor)
    polylineAnnotationOSM.lineWidth = 6
    return polylineAnnotationOSM
  }
}
