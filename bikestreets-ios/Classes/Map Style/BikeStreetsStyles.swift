
import Foundation
import UIKit
import Mapbox

/**
 * List of available map styles, which are URLs in mapbox. List of available styles here: https://docs.mapbox.com/api/maps/#styles
 */
struct BikeStreetsMapTypes {
    static let bikeStreets = Bundle.main.url(forResource: "bike streets map style", withExtension: "json")
    static let street = URL(string: "mapbox://styles/mapbox/streets-v11")
    static let satellite = URL(string: "mapbox://styles/mapbox/satellite-v9")
    static let satelliteWithLabels = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")
}

/**
 * Style elements for Bike Streets
 */
struct BikeStreetsStyles {
    static let bikeStreetBlue = UIColor(red: 52/255, green: 90/255, blue: 168/255, alpha: 0.7)
    static let trailGreen = UIColor(red: 0/255, green: 178/255, blue: 0/255, alpha: 0.7)
    static let bikeLaneOrange = UIColor(red: 216/255, green: 146/255, blue: 15/255, alpha: 0.7)
    static let bikeSidewalkYellow = UIColor(red: 255/255, green: 255/255, blue: 0/255, alpha: 0.7)
    static let walkBlack = UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.7)

    // Use `NSExpression` to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
    private static let lineWidth =  NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
          [14: 2, 18: 8])
    
    static func style(forLayer layerName: String, source: MGLShapeSource) -> MGLStyleLayer {
        // Create new layer for the line.
        let layer = MGLLineStyleLayer(identifier: layerName, source: source)
        
        // Set the line join and cap to a rounded end.
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        
        let lineColor: UIColor!
        switch layerName {
        case "trails":
            lineColor = trailGreen
        case "bikelanes":
            lineColor = bikeLaneOrange
        case "bikesidewalks":
            lineColor = bikeSidewalkYellow
        case "walk":
            lineColor = walkBlack
        case "bikestreets":
            fallthrough
        default:
            lineColor = bikeStreetBlue
        }

        layer.lineColor = NSExpression(forConstantValue: lineColor)
        layer.lineWidth = lineWidth
                    
        return layer
    }
}
