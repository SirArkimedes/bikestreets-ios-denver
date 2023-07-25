//
//  MapsViewController.swift
//  MapboxTester
//
//  Created by Matt Robinson on 6/30/23.
//

import MapboxMaps
import MapboxSearch

protocol ExampleController: UIViewController {}

class MapsViewController: UIViewController, ExampleController {
  let mapView = MapView(frame: .zero)
  lazy var polylineAnnotationManager = mapView.annotations.makePolylineAnnotationManager()
  lazy var annotationsManager = mapView.annotations.makePointAnnotationManager()
  lazy var circleAnnotationsManager = mapView.annotations.makeCircleAnnotationManager()

  override func viewDidLoad() {
    super.viewDidLoad()

    view.addSubview(mapView)

    mapView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.leftAnchor.constraint(equalTo: mapView.leftAnchor),
      view.rightAnchor.constraint(equalTo: mapView.rightAnchor),

      view.topAnchor.constraint(equalTo: mapView.topAnchor),
      view.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
    ])

    // Show user location
    mapView.location.options.puckType = .puck2D()

    // Show Mapbox styles
    DispatchQueue.main.async {
      self.loadMapFromShippedResources()
    }
  }

  func showAnnotations(results: [SearchResult], cameraShouldFollow: Bool = true) {
    annotationsManager.annotations = results.map(PointAnnotation.init)

    circleAnnotationsManager.annotations = results.map { result in
      var annotation = CircleAnnotation(centerCoordinate: result.coordinate)
      annotation.circleColor = .init(.red)
      return annotation
    }

    if cameraShouldFollow {
      cameraToAnnotations(annotationsManager.annotations)
    }
  }

  func cameraToAnnotations(_ annotations: [PointAnnotation]) {
    cameraToCoordinates(annotations.map(\.point.coordinates))
  }

  func cameraToCoordinates(_ coordinates: [CLLocationCoordinate2D]) {
    if coordinates.count == 1, let coordinate = coordinates.first {
      mapView.camera.fly(to: .init(center: coordinate, zoom: 15), duration: 0.25, completion: nil)
    } else {
      let coordinatesCamera = mapView.mapboxMap.camera(for: coordinates,
                                                       padding: UIEdgeInsets(top: 24, left: 24, bottom: 24, right: 24),
                                                       bearing: nil,
                                                       pitch: nil)
      mapView.camera.fly(to: coordinatesCamera, duration: 0.25, completion: nil)
    }
  }

  func showAnnotation(_ result: SearchResult) {
    showAnnotations(results: [result])
  }

  func showAnnotation(_ favorite: FavoriteRecord) {
    annotationsManager.annotations = [PointAnnotation(favoriteRecord: favorite)]

    cameraToAnnotations(annotationsManager.annotations)
  }

  func showError(_ error: Error) {
    let alertController = UIAlertController(title: nil, message: error.localizedDescription, preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

    present(alertController, animated: true, completion: nil)
  }
}

// MARK: - Load Bike Streets Data

extension MapsViewController {
  /**
   * Load the default Bike Streets map from KML resources files bundled into the app
   */
  private func loadMapFromShippedResources() {
    // TODO: Versioning scheme for the geojson data
    // TODO: Do we have a cached/downloaded version of the geojson data?
    // TODO: Is our cached version of geojson the latest & greatest?
    if let fileURLs = Bundle.main.urls(forResourcesWithExtension: "geojson", subdirectory: nil) {
      for fileURL in fileURLs {
        loadMapLayerFrom(fileURL)
      }
    }
  }

  /// Load GeoJSON file from local bundle and decode into a `FeatureCollection`.
  ///
  /// From: https://docs.mapbox.com/ios/maps/examples/line-gradient/
  private func decodeGeoJSON(from filePath: URL) throws -> FeatureCollection? {
    var featureCollection: FeatureCollection?
    do {
      let data = try Data(contentsOf: filePath)
      featureCollection = try JSONDecoder().decode(FeatureCollection.self, from: data)
    } catch {
      print("Error parsing data: \(error)")
    }
    return featureCollection
  }

  /// From: https://docs.mapbox.com/ios/maps/examples/line-gradient/
  private func loadMapLayerFrom(_ fileURL: URL) {
    // Attempt to decode GeoJSON from file bundled with application.
    guard let featureCollection = try? decodeGeoJSON(from: fileURL /* "GradientLine" */ ) else { return }

    //    let geoJSONDataSourceIdentifier = "geoJSON-data-source"
    // Get the layer name from the file name. We'll use it in a couple of places
    guard let geoJSONDataSourceIdentifier = fileURL.lastPathComponent.layerName() else {
      fatalError("Unable to locate layer name in file name \(fileURL.lastPathComponent)")
    }

    // Create a GeoJSON data source.
    var geoJSONSource = GeoJSONSource()
    geoJSONSource.data = .featureCollection(featureCollection)
    geoJSONSource.lineMetrics = true // MUST be `true` in order to use `lineGradient` expression

    // Create a line layer
    let lineLayer = BikeStreetsStyles.style(forLayer: geoJSONDataSourceIdentifier, source: geoJSONDataSourceIdentifier)

    // Add the source and style layer to the map style.
    try! mapView.mapboxMap.style.addSource(geoJSONSource, id: geoJSONDataSourceIdentifier)
    try! mapView.mapboxMap.style.addLayer(lineLayer, layerPosition: nil)
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

// MARK: -

extension PointAnnotation {
  init(searchResult: SearchResult) {
    self.init(coordinate: searchResult.coordinate)
    textField = searchResult.name
  }

  init(favoriteRecord: FavoriteRecord) {
    self.init(coordinate: favoriteRecord.coordinate)
    textField = favoriteRecord.name
  }
}

// MARK: -

extension CLLocationCoordinate2D {
  static let sanFrancisco = CLLocationCoordinate2D(latitude: 37.7911551, longitude: -122.3966103)
}
