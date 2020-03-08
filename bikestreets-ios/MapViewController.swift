
import UIKit
import Mapbox

// MARK: - Defaults for the map view
struct MapViewDefaults {
    static let mapStyle = BikeStreetsMapTypes.street
    static let latitude = 39.7390
    static let longitude = -104.9911
    static let detailLevel = 14.0
}

// MARK: -
class MapViewController: UIViewController, MGLMapViewDelegate {

    // UI Objects in the storyboard
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var buttonWrapperView: UIView!
    @IBOutlet weak var debugInfoLabel: UILabel!
    
    // Array to hold on to observer objects for watching changes to UserDefaults
    var userSettingObservers: [NSObject] = [NSObject]()
            
    // MARK: - UIViewController overrides
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.delegate = self
        
        // Initlize the map location with our default. We'll center it on the user later (assuming she gives us
        // permission)
        mapView.setCenter(CLLocationCoordinate2D(latitude: MapViewDefaults.latitude,
                                                 longitude: MapViewDefaults.longitude),
                          zoomLevel: MapViewDefaults.detailLevel,
                          animated: false)

        // Street or satellite view?
        configureMapStyle()
        configureMapPerspective()
        configureKeepScreenOn()

        // Style the buttons
        buttonWrapperView.layer.cornerRadius = 5.0
        buttonWrapperView.layer.masksToBounds = true
     
        configureUserSettingObservers()
        
        #if DEBUG
        debugInfoLabel.isHidden = false
        #else
        debugInfoLabel.isHidden = true
        #endif
    }

    override func viewDidAppear(_ animated: Bool) {
        if !TermsManager.hasAcceptedCurrentTerms() {
            guard let termsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TermsViewController") as? TermsViewController else {
                fatalError("Unable to locate the TermsViewController")
            }
            present(termsViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - MGLMapViewDelegate
    
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // Wait until the map is loaded before adding to the map.
        loadMapFromShippedResources()
    }
    
    #if DEBUG
    func mapViewRegionIsChanging(_ mapView: MGLMapView) {
        debugInfoLabel.text = "Zoom Level: \(mapView.zoomLevel.rounded())"
    }
    #endif
    
    // MARK: - Load Bike Streets Data
    
    /**
     * Load the default Bike Streets map from KML resources files bundled into the app
     */
    func loadMapFromShippedResources() {
        // TODO: Versioning scheme for the geojson data
        // TODO: Do we have a cached/downloaded version of the geojson data?
        // TODO: Is our cached version of geojson the latest & greatest?

        if let fileURLs = Bundle.main.urls(forResourcesWithExtension: "geojson", subdirectory: nil) {
            for fileURL in fileURLs {
                self.loadMapLayerFrom(fileURL)
            }
        }
    }
 
    func loadMapLayerFrom(_ fileURL: URL) {
        // MGLMapView.style is optional, so you must guard against it not being set.
        guard let style = self.mapView.style else {
            return
        }
        
        // Get the layer name from the file name. We'll use it in a couple of places
        guard let layerName = fileURL.lastPathComponent.layerName() else {
            fatalError("Unable to locate layer name in file name \(fileURL.lastPathComponent)")
        }

        // Jump off the main thread to do the heavy lifting of reading the file and parsing the JSON
        DispatchQueue.global().async {
            // Get the geoJSON out of the file
            guard let jsonData = try? Data(contentsOf: fileURL) else {
                preconditionFailure("Failed to parse GeoJSON file")
            }
            
            // Parse the geoJSON into a Shape object
            guard let shapeFromGeoJSON = try? MGLShape(data: jsonData, encoding: String.Encoding.utf8.rawValue) else {
                fatalError("Could not generate MGLShape")
            }
            
            // Create the shape and layer from the JSON
            let source = MGLShapeSource(identifier: layerName, shape: shapeFromGeoJSON, options: nil)
            let layer = BikeStreetsStyles.style(forLayer: layerName, source: source)
            
            // Jump back to the main thread for the UI work of rendering the shape and layer
            DispatchQueue.main.async {
                // Add our GeoJSON data to the map as an MGLGeoJSONSource.
                // We can then reference this data from an MGLStyleLayer.
                style.addSource(source)
                style.addLayer(layer)
            }
        }
    }
    
    // MARK: - Map Configuration Methods
    
    /**
     * Street or Satellite view?
     */
    func configureMapStyle() {
        if UserSettings.mapViewType == .satellite {
            mapView.styleURL = BikeStreetsMapTypes.satelliteWithLabels
        } else {
            mapView.styleURL = BikeStreetsMapTypes.street
        }
    }
    
    /**
     * Change the map's perspective depending upon the user setting
     */
    func configureMapPerspective(isChange: Bool = false) {
        mapView.showsUserLocation = true
        
        // How should we orient the map? Fixed or Direction of Travel?
        if (UserSettings.mapOrientation == .directionOfTravel) {
            mapView.userTrackingMode = .followWithHeading
            mapView.showsUserHeadingIndicator = true
        } else {
            mapView.userTrackingMode = .follow
            mapView.showsUserHeadingIndicator = false

            if isChange {
                // We should not change the viewpoint rotation & (re)center the map unless this is a change
                // in map perspective.
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
        guard let userLocation = mapView.userLocation else {
            return
        }
        
        if !mapView.isUserLocationVisible {
            mapView.setCenter(userLocation.coordinate, animated: true)
        }
    }
    
    /**
     * Watch for changes to the UserSettings
     */
    func configureUserSettingObservers() {
        var observer = UserSettings.$mapViewTypeRaw.observe { [weak self] old, new in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,
                                          execute: {
                                            strongSelf.configureMapStyle()
            })
        }
        userSettingObservers.append(observer)
        observer = UserSettings.$mapOrientationRaw.observe { [weak self] old, new in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,
                                          execute: {
                                            strongSelf.configureMapPerspective(isChange: true)
            })
        }
        userSettingObservers.append(observer)
        observer = UserSettings.$preventScreenLockOnMap.observe { [weak self] old, new in
            guard let strongSelf = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5,
                                          execute: {
                                            strongSelf.configureKeepScreenOn()
            })
        }
        userSettingObservers.append(observer)
    }
    
    // MARK: - Button Action Methods
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        guard let mapSettingsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapSettingsViewController") as? MapSettingsViewController else {
            fatalError("Unable to locate the MapSettingsViewController")
        }

        let navController = UINavigationController(rootViewController: mapSettingsViewController)
        present(navController, animated: true, completion: nil)
    }
    
    @IBAction func locationButtonTapped(_ sender: Any) {
        centerMapOnCurrentLocation()
    }
}

// MARK: -
private extension String {
    func layerName() -> String? {
        let fileNameComponents = components(separatedBy: "-")
        if fileNameComponents.count >= 2 {
            return fileNameComponents[1]
        }
        return nil
    }
}
