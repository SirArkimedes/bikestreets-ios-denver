
import Foundation
import UIKit
import Mapbox

extension UIColor {
    /**
     * Convenience initalizer for creating a color from R, G, & B hex values
     *
     * Usage: let color = UIColor(red: 0xFF, green: 0xFF, blue: 0xFF)
     */
    convenience init(red: Int, green: Int, blue: Int, alpha: CGFloat = 1.0) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")

        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: alpha)
    }

    /**
     * Convenience initalizer for creating a color from an RGB Hex value
     *
     * Usage: let color = UIColor(rgb: 0xFFFFFF)
     */
    convenience init(rgb: Int, alpha: CGFloat = 1.0) {
        self.init(red: (rgb >> 16) & 0xFF,
                  green: (rgb >> 8) & 0xFF,
                  blue: rgb & 0xFF,
                  alpha: alpha
        )
    }
}

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
    private static let bikeStreetLayer = MapLayerSpec("bikestreets", rgb: 0x345aa8, description: "Bike Street")
    private static let trailLayer = MapLayerSpec("trails", rgb: 0x7a8a47, description: "Trail")
    private static let bikeLaneLayer = MapLayerSpec("bikelanes", rgb: 0xe8238b, description: "Bike Lane")
    private static let bikeSidewalkLayer = MapLayerSpec("bikesidewalks", rgb: 0xffcf22, description: "Bike on Sidewalk")
    private static let walkBikeLayer = MapLayerSpec("walk", rgb: 0x55af9c, description: "Walk your Bike")

    static let mapLayerSpecs: [MapLayerSpec] = [
        bikeStreetLayer,
        trailLayer,
        bikeLaneLayer,
        bikeSidewalkLayer,
        walkBikeLayer,
    ]
    
    static func mapLayerSpec(forLayer layerName: String) -> MapLayerSpec? {
        for layerSpec in mapLayerSpecs {
            if layerSpec.name == layerName {
                return layerSpec
            }
         }
        return nil
    }
    
    static func mapLayerColor(forLayer layerName: String) -> UIColor {
        guard let layerSpec = mapLayerSpec(forLayer: layerName) else {
            fatalError("Cannot find map layer spec for layer id \(layerName)")
        }
        return layerSpec.color
    }
    
    // Use `NSExpression` to smoothly adjust the line width from 2pt to 20pt between zoom levels 14 and 18. The `interpolationBase` parameter allows the values to interpolate along an exponential curve.
    private static let lineWidth =  NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
          [14: 2, 18: 8])
    
    static func style(forLayer layerName: String, source: MGLShapeSource) -> MGLStyleLayer {
        // Create new layer for the line.
        let layer = MGLLineStyleLayer(identifier: layerName, source: source)
        
        // Set the line join and cap to a rounded end.
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")

        // Get the line color for this layer
        let lineColor = mapLayerColor(forLayer: layerName)

        layer.lineColor = NSExpression(forConstantValue: lineColor)
        layer.lineWidth = lineWidth
                    
        return layer
    }
}

struct MapLayerSpec {
    private static let bikeStreetAlpha: CGFloat = 0.7

    let name: String
    let color: UIColor
    let description: String
    
    init(_ name: String, rgb: Int, description: String) {
        self.name = name
        self.color = UIColor(rgb: rgb, alpha: MapLayerSpec.bikeStreetAlpha)
        self.description = NSLocalizedString(description, comment: "")
    }
}
