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
  private let mapboxControllers: (searchController: MapboxSearchController, panelController: MapboxPanelController) = {
//    let locationProvider = DefaultLocationProvider(locationManager: CLLocationManager())
//    let configuration = Configuration(locationProvider: locationProvider)

    //    let locationProvider = PointLocationProvider(coordinate: .sanFrancisco)
    //    var configuration = Configuration(locationProvider: locationProvider)

    let searchController = MapboxSearchController() //(configuration: configuration)

    let panelController = MapboxPanelController(rootViewController: searchController)

    return (searchController, panelController)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    DispatchQueue.main.async {
//      //    let cameraOptions = CameraOptions(center: .sanFrancisco, zoom: 15)
//      // CUSTOM FOR DENVER
//      let cameraOptions = CameraOptions(
//        center: CLLocationCoordinate2D( latitude: 39.753580116073685, longitude: -105.04056378182935),
//        zoom: 15.5
//      )
//
//      self.mapView.camera.fly(to: cameraOptions, duration: 1, completion: nil)

//      self.mapView.location.options.puckType = .puck2D()
      let followPuckViewportState = self.mapView.viewport.makeFollowPuckViewportState(
        options: FollowPuckViewportStateOptions(
          padding: UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0),
          bearing: .heading,
          pitch: 0))
      self.mapView.viewport.transition(to: followPuckViewportState) { success in
        // the transition has been completed with a flag indicating whether the transition succeeded
      }
    }

    mapboxControllers.searchController.delegate = self

    mapboxControllers.panelController.willMove(toParent: self)
    addChild(mapboxControllers.panelController)
    mapboxControllers.panelController.didMove(toParent: self)
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
