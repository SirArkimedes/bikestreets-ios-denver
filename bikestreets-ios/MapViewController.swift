
import UIKit
import ArcGIS

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: AGSMapView!
    
    // MARK: ViewController overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultLatitude = 39.7430
        let defaultLongitude = -104.9706
        let defaultDetailLevel = 11
        
        // Display a map using the ArcGIS Online imagery basemap service
        mapView.map = AGSMap(basemapType: .lightGrayCanvas, latitude: defaultLatitude, longitude: defaultLongitude, levelOfDetail: defaultDetailLevel)
        
        
        loadMapFromShippedResources()

        // TODO: Versioning scheme for the KML data
        // TODO: Do we have a cached/downloaded version of the KML data?
        // TODO: Is our cached version of KML the latest & greatest?        

        displayCurrentLocation()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    // MARK: --
    
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
    
    func displayCurrentLocation() {
        mapView.locationDisplay.initialZoomScale = 20000
        mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanMode.recenter
        
        mapView.locationDisplay.useCourseSymbolOnMovement = true
        
        mapView.locationDisplay.start { [weak self] (error:Error?) -> Void in
            if let error = error {
                // TODO: Show an alert through a centralized infrastructure
//                self?.showAlert(withStatus: error.localizedDescription)
            }
        }
    }
    /**
     * Recenter the map on the current location, but don't change the zoom level
     */
    func centerMapOnCurrentLocation() {
        if let currentPosition = mapView.locationDisplay.location?.position {
            mapView.setViewpointCenter(currentPosition) { [weak self] (finished: Bool) in
            }
        }
    }
    
    // MARK: Button Action Methods
    
    @IBAction func infoButtonTapped(_ sender: Any) {
    }
    
    @IBAction func locationButtonTapped(_ sender: Any) {
        centerMapOnCurrentLocation()
    }
}

