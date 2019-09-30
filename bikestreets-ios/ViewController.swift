
import UIKit
import ArcGIS

class ViewController: UIViewController {

    @IBOutlet weak var mapView: AGSMapView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultLatitude = 39.7430
        let defaultLongitude = -104.9706
        let defaultDetailLevel = 12
        
        // Display a map using the ArcGIS Online imagery basemap service
        self.mapView.map = AGSMap(basemapType: .streetsVector, latitude: defaultLatitude, longitude: defaultLongitude, levelOfDetail: defaultDetailLevel)
     
        loadMapFromShippedResources()

        // TODO: Versioning scheme for the KML data
        // TODO: Do we have a cached/downloaded version of the KML data?
        // TODO: Is our cached version of KML the latest & greatest?        
    }

    /**
     * Load the default Bike Streets map from KML resources files bundled into the app
     */
    func loadMapFromShippedResources() {
        if let kmlFileUrls = Bundle.main.urls(forResourcesWithExtension: "kml", subdirectory: nil) {
            for kmlFileUrl in kmlFileUrls {
                if let layer = loadMapLayerFrom(layerUrl: kmlFileUrl) {
                    self.mapView.map?.operationalLayers.add(layer)
                }
            }
        }
    }
 
    func loadMapLayerFrom(layerUrl: URL) -> AGSLayer? {
        let kmlDataset = AGSKMLDataset(url: layerUrl)
        let kmlLayer = AGSKMLLayer(kmlDataset: kmlDataset)
        
        return kmlLayer
    }
}

