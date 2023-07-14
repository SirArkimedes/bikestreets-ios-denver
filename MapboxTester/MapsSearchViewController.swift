//
//  MapsSearchViewController.swift
//  MapboxTester
//
//  Created by Matt Robinson on 6/30/23.
//

import UIKit
import MapboxMaps
import MapboxSearch
import MapboxSearchUI
import SwiftUI

struct MapsSearchViewController: UIViewControllerRepresentable {
  typealias UIViewControllerType = MapsSearchViewControllerInternal

  func makeUIViewController(context: Context) -> MapsSearchViewControllerInternal {
    return MapsSearchViewControllerInternal()
  }

  func updateUIViewController(_ uiViewController: MapsSearchViewControllerInternal, context: Context) {
    // no-op
  }
}

final class MapsSearchViewControllerInternal: UIViewController {
  var searchController = MapboxSearchController()
  var mapView: MapView?
  var annotationManager: PointAnnotationManager?

  override func viewDidLoad() {
    super.viewDidLoad()

    // Search setup
    searchController.delegate = self
    let panelController = MapboxPanelController(rootViewController: searchController)
    addChild(panelController)

    // Map setup

    // CUSTOM FOR DENVER
    let cameraOptions = CameraOptions(
      center: CLLocationCoordinate2D( latitude: 39.753580116073685, longitude: -105.04056378182935),
      zoom: 15.5
    )
    let myMapInitOptions = MapInitOptions(cameraOptions: cameraOptions)

    let mapView = MapView(frame: .zero, mapInitOptions: myMapInitOptions)
//    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    self.mapView = mapView
    view.addSubview(mapView)

    mapView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      view.leftAnchor.constraint(equalTo: mapView.leftAnchor),
      view.rightAnchor.constraint(equalTo: mapView.rightAnchor),

      view.topAnchor.constraint(equalTo: mapView.topAnchor),
      view.bottomAnchor.constraint(equalTo: mapView.bottomAnchor),
    ])

    annotationManager = mapView.annotations.makePointAnnotationManager()
  }

  func showResults(_ results: [SearchResult]) {
    let annotations = results.map { searchResult -> PointAnnotation in
      var annotation = PointAnnotation(coordinate: searchResult.coordinate)
      annotation.textField = searchResult.name
      annotation.textOffset = [0, -2]
      annotation.textColor = .init(.red) // ColorRepresentable(color: .red)
//      annotation.image = .default
      return annotation
    }

    annotationManager?.annotations = annotations
//    annotationManager?.syncAnnotations(annotations)
    if case let .point(point) = annotations.first?.geometry {
      let options = CameraOptions(center: point.coordinates)
      mapView?.mapboxMap.setCamera(to: options)
    }
  }
}

extension MapsSearchViewControllerInternal: SearchControllerDelegate {
  func categorySearchResultsReceived(category: MapboxSearchUI.SearchCategory, results: [MapboxSearch.SearchResult]) {
    showResults(results)
  }

  func categorySearchResultsReceived(results: [SearchResult]) {
    showResults(results)
  }

  func searchResultSelected(_ searchResult: SearchResult) {
    showResults([searchResult])
  }

  func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
    showResults([userFavorite])
  }
}
