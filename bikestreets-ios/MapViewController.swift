
import UIKit
import ArcGIS

class MapViewController: UIViewController {

    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var buttonWrapperView: UIView!
    
    // Array to hold on to observer objects for watching changes to UserDefaults
    var userSettingObservers: [NSObject]?
        
    /**
     * Defaults for the map view
     */
    struct MapViewDefaults {
        static let basemapType = AGSBasemapType.lightGrayCanvasVector
        static let latitude = 39.7390
        static let longitude = -104.9911
        static let detailLevel = 15
    }
    
    // MARK: UIViewController overrides
    override func viewDidLoad() {
        super.viewDidLoad()

        // Street or satellite view?
        var basemapType: AGSBasemapType = MapViewDefaults.basemapType
        if UserSettings.mapViewType == MapViewType.satellite.rawValue {
            basemapType = .imageryWithLabelsVector
        }
        
        // Display a map using the ArcGIS Online imagery basemap service
        mapView.map = AGSMap(basemapType: basemapType,
                             latitude: MapViewDefaults.latitude,
                             longitude: MapViewDefaults.longitude,
                             levelOfDetail: MapViewDefaults.detailLevel)
        
        
        loadMapFromShippedResources()

        // TODO: Versioning scheme for the KML data
        // TODO: Do we have a cached/downloaded version of the KML data?
        // TODO: Is our cached version of KML the latest & greatest?

        // Configure
        configureMapPerspective()
        configureKeepScreenOn()
        
        mapView.locationDisplay.useCourseSymbolOnMovement = true

        // Begin the location display (ie show the little dot with the user's location)
        mapView.locationDisplay.start { [weak self] (error:Error?) -> Void in
            guard let strongSelf = self else { return }
            if let error = error {
                // TODO: Show an alert through a centralized infrastructure
//                self?.showAlert(withStatus: error.localizedDescription)
            }
        }

        // Style the buttons
        buttonWrapperView.layer.cornerRadius = 5.0
        buttonWrapperView.layer.masksToBounds = true
     
        configureUserSettingObservers()
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
    
    /**
     * Street or Satellite view?
     */
    func changeBaseMapType() {
        if UserSettings.mapViewType == MapViewType.satellite.rawValue {
            mapView.map?.basemap = .imageryWithLabelsVector()
        } else {
            mapView.map?.basemap = .lightGrayCanvasVector()
        }
    }
    
    /**
     * Change the map's perspective depending upon the user setting
     */
    func configureMapPerspective(isChange: Bool = false) {
        // How should we orient the map? North or Direction of Travel?
        if (UserSettings.mapOrientation == MapDirectionOfTravel.directionOfTravel.rawValue) {
            mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanMode.navigation
        } else {
            mapView.locationDisplay.autoPanMode = AGSLocationDisplayAutoPanMode.recenter
            if isChange {
                // We should not change the viewpoint rotation & (re)center the map unless this is a change
                // in map perspective.
                mapView.setViewpointRotation(0.0, completion: nil)
                centerMapOnCurrentLocation()
            }
        }
    }
    
    /**
     * Do we need to prevent the screen from locking?
     */
    func configureKeepScreenOn() {
        UIApplication.shared.isIdleTimerDisabled = UserSettings.preventScreenLockOnMap
    }
    
    /**
     * Recenter the map on the current location, but don't change the zoom level
     */
    func centerMapOnCurrentLocation() {
        if let currentPosition = mapView.locationDisplay.location?.position {
            mapView.setViewpointCenter(currentPosition)
        }
    }
    
    /**
     * Watch for changes to the UserSettings
     */
    func configureUserSettingObservers() {
        var observer = UserSettings.$mapViewType.observe { [weak self] old, new in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,
                                          execute: {
                                            strongSelf.changeBaseMapType()
            })
        }
        userSettingObservers?.append(observer)
        observer = UserSettings.$mapOrientation.observe { [weak self] old, new in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,
                                          execute: {
                                            strongSelf.configureMapPerspective(isChange: true)
            })
        }
        userSettingObservers?.append(observer)
        observer = UserSettings.$preventScreenLockOnMap.observe { [weak self] old, new in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,
                                          execute: {
                                            strongSelf.configureKeepScreenOn()
            })
        }
        userSettingObservers?.append(observer)
    }
    
    // MARK: Button Action Methods
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        let mapSettingsViewController = MapSettingsViewController()
        let navController = UINavigationController(rootViewController: mapSettingsViewController)
        present(navController, animated: true, completion: nil)
    }
    
    @IBAction func locationButtonTapped(_ sender: Any) {
        centerMapOnCurrentLocation()
    }
}

