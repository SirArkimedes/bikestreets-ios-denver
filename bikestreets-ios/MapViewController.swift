
import UIKit
import Mapbox

// MARK: - Defaults for the map view
struct MapViewDefaults {
    static let latitude = 39.7390
    static let longitude = -104.9911
    static let zoomLevel = 15.0
}

fileprivate struct MapViewLimits {
    static let maxZoomLevel = 19.0
    static let minZoomLevel = 10.0
}

// MARK: -
class MapViewController: UIViewController {

    // UI Objects in the storyboard
    @IBOutlet weak var mapView: MGLMapView!
    @IBOutlet weak var buttonWrapperView: UIView!
    @IBOutlet weak var infoButton: UIButton!
    @IBOutlet weak var locationButton: UIButton!
    @IBOutlet weak var debugInfoLabel: UILabel!
    
    private let logger = Logger(name: "MapViewController")
    
    // Array to hold on to observer objects for watching changes to UserDefaults
    private var userSettingObservers: [NSObject] = [NSObject]()
            
    private var locationArrowSolid: UIImage!
    private var locationArrowOutline: UIImage!
    
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
                          zoomLevel: UserSettings.mapZoomLevel,
                          animated: false)

        // Always show the compass - Denverites navigate by ordinals in a way many other cities do not
        mapView.compassView.compassVisibility = .visible
        mapView.compassViewMargins = CGPoint(x: 10, y: buttonWrapperView.frame.height + 20)
        mapView.showsUserLocation = true

        // Street or satellite view?
        configureMapStyle()
        configureKeepScreenOn()
        configureUserTrackingMode()

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
        // If the user has not accepted the current Terms of Service for the app then show the
        // Terms view.
        if !TermsManager.hasAcceptedCurrentTerms() {
            guard let termsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TermsViewController") as? TermsViewController else {
                fatalError("Unable to locate the TermsViewController")
            }
            termsViewController.modalPresentationStyle = .overFullScreen
            present(termsViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Button Action Methods
    @IBAction func infoButtonTapped(_ sender: Any) {
        logger.log(eventName: "map info button tapped")
        
        guard let mapSettingsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapSettingsViewController") as? MapSettingsViewController else {
            fatalError("Unable to locate the MapSettingsViewController")
        }

        let navController = UINavigationController(rootViewController: mapSettingsViewController)
        present(navController, animated: true, completion: nil)
    }
    
    @IBAction func locationButtonTapped(_ sender: Any) {
        logger.log(eventName: "map location button tapped")

        centerMapOnCurrentLocation()

        // Re-enable tracking/panning because this gets disabled when the user starts panning the map
        configureUserTrackingMode()
    }
}

// MARK: - MGLMapViewDelegate
extension MapViewController: MGLMapViewDelegate {
    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        // Wait until the map is loaded before adding to the map.
        loadMapFromShippedResources()
    }
    
    func mapView(_ mapView: MGLMapView, regionDidChangeWith reason: MGLCameraChangeReason, animated: Bool) {
        #if DEBUG
        debugInfoLabel.text = "Zoom Level: \(mapView.zoomLevel.rounded())"
        #endif

        let oldZoomLevel = UserSettings.mapZoomLevel
        var newZoomLevel = mapView.zoomLevel.rounded()
        
        // Bail if the zoom level has not changed
        guard oldZoomLevel != newZoomLevel else {
            return
        }
        
        // Min & Max zoom levels that we'll save. Users can Zoom way in or way out, but we don' want to save
        // that for the next time the app starts up.
        if newZoomLevel > MapViewLimits.maxZoomLevel {
            newZoomLevel = MapViewLimits.maxZoomLevel
        } else if newZoomLevel < MapViewLimits.minZoomLevel {
            newZoomLevel = MapViewLimits.minZoomLevel
        }
        
        // Save the user's zoom level
        UserSettings.mapZoomLevel = newZoomLevel
    }
    
    func mapView(_ mapView: MGLMapView, didChange mode: MGLUserTrackingMode, animated: Bool) {
        if locationArrowSolid == nil {
            if #available(iOS 13.0, *) {
                locationArrowSolid = UIImage(systemName: "location.fill")
                locationArrowOutline = UIImage(systemName: "location")
            } else {
                locationArrowSolid = UIImage(named: "location-arrow-solid-iOS-12")
                locationArrowOutline = UIImage(named: "location-arrow-outline-iOS-12")
            }
        }
        
        // If the map is no longer tracking the user (likely because the user panned the map), we need to
        // change from the arrow on the location button from solid to outline.
        if mode == .none {
            locationButton.setImage(locationArrowOutline, for: .normal)
        } else {
            locationButton.setImage(locationArrowSolid, for: .normal)
        }
    }
}

// MARK: - Load Bike Streets Data
extension MapViewController {
    /**
     * Load the default Bike Streets map from KML resources files bundled into the app
     */
    private func loadMapFromShippedResources() {
        // TODO: Versioning scheme for the geojson data
        // TODO: Do we have a cached/downloaded version of the geojson data?
        // TODO: Is our cached version of geojson the latest & greatest?
        if let fileURLs = Bundle.main.urls(forResourcesWithExtension: "geojson", subdirectory: nil) {
            for fileURL in fileURLs {
               self.loadMapLayerFrom(fileURL)
            }
        }
    }
    
    private func loadMapLayerFrom(_ fileURL: URL) {
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
                if let roadLabelLayer = style.layer(withIdentifier: "road-label") {
                    style.insertLayer(layer, below: roadLabelLayer)
                } else {
                    style.addLayer(layer)
                }
            }
        }
    }
}

// MARK: -
fileprivate extension String {
    func layerName() -> String? {
        let fileNameComponents = components(separatedBy: "-")
        if fileNameComponents.count >= 2 {
            return fileNameComponents[1]
        }
        return nil
    }
}

// MARK: - Map Configuration Methods
extension MapViewController {
    /**
     * Street or Satellite view?
     */
    private func configureMapStyle() {
        if UserSettings.mapViewType == .satellite {
            mapView.styleURL = BikeStreetsMapTypes.satelliteWithLabels
        } else {
            mapView.styleURL = BikeStreetsMapTypes.bikeStreets
        }
    }
    
    /**
     * Enable user tracking (i.e. pan/move the map as the user moves)
     */
    private func configureUserTrackingMode() {
        if (UserSettings.mapOrientation == .directionOfTravel) {
            mapView.userTrackingMode = .followWithHeading
        } else {
            mapView.userTrackingMode = .follow
        }
    }
    
    /**
     * Do we need to prevent the screen from locking?
     */
    private func configureKeepScreenOn() {
        UIApplication.shared.isIdleTimerDisabled = UserSettings.preventScreenLockOnMap
    }
    
    /**
     * Recenter the map on the current location, but don't change the zoom level
     */
    private func centerMapOnCurrentLocation() {
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
    private func configureUserSettingObservers() {
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
                                            strongSelf.configureUserTrackingMode()
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
}
