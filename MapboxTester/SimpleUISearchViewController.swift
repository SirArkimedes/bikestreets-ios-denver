//
//  SimpleUISearchViewController.swift
//  MapboxTester
//
//  Created by Matt Robinson on 6/30/23.
//

import UIKit
import SwiftUI
import MapboxMaps
import MapboxSearchUI

struct SimpleUISearchViewController: UIViewControllerRepresentable {
  typealias UIViewControllerType = SimpleUISearchViewControllerInternal

  func makeUIViewController(context: Context) -> SimpleUISearchViewControllerInternal {
    return SimpleUISearchViewControllerInternal()
  }

  func updateUIViewController(_ uiViewController: SimpleUISearchViewControllerInternal, context: Context) {
    // no-op
  }
}

class SimpleUISearchViewControllerInternal: MapsViewController {

  lazy var searchController: MapboxSearchController = {
//    let locationProvider = PointLocationProvider(coordinate: .sanFrancisco)
//    var configuration = Configuration(locationProvider: locationProvider)

    return MapboxSearchController() //configuration: configuration)
  }()

  lazy var panelController = MapboxPanelController(rootViewController: searchController)

  override func viewDidLoad() {
    super.viewDidLoad()

//    let cameraOptions = CameraOptions(center: .sanFrancisco, zoom: 15)
    // CUSTOM FOR DENVER
    let cameraOptions = CameraOptions(
      center: CLLocationCoordinate2D( latitude: 39.753580116073685, longitude: -105.04056378182935),
      zoom: 15.5
    )

    mapView.camera.fly(to: cameraOptions, duration: 1, completion: nil)

    searchController.delegate = self
    addChild(panelController)
  }
}

extension SimpleUISearchViewControllerInternal: SearchControllerDelegate {
  func categorySearchResultsReceived(category: SearchCategory, results: [SearchResult]) {
    showAnnotations(results: results)
  }

  func searchResultSelected(_ searchResult: SearchResult) {
    showAnnotation(searchResult)
  }

  func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
    showAnnotation(userFavorite)
  }
}
