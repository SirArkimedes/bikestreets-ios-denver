//
//  SimpleUISearchViewController.swift
//  MapboxTester
//
//  Created by Matt Robinson on 6/30/23.
//

import MapboxMaps
import MapboxSearchUI
import SwiftUI
import UIKit

struct SimpleUISearchViewController: UIViewControllerRepresentable {
  typealias UIViewControllerType = SimpleUISearchViewControllerInternal

  func makeUIViewController(context _: Context) -> SimpleUISearchViewControllerInternal {
    SimpleUISearchViewControllerInternal()
  }

  func updateUIViewController(_: SimpleUISearchViewControllerInternal, context _: Context) {
    // no-op
  }
}

final class SimpleUISearchViewControllerInternal: MapsViewController {
  private let mapboxControllers: (searchController: MapboxSearchController, panelController: MapboxPanelController) = {
    let locationProvider = DefaultLocationProvider()
    let configuration = Configuration(
      categoryDataProvider: BikeStreetsCategoryDataProvider(),
      locationProvider: locationProvider
    )

    let searchController = MapboxSearchController(configuration: configuration)

    let panelController = MapboxPanelController(rootViewController: searchController)

    return (searchController, panelController)
  }()

  override func viewDidLoad() {
    super.viewDidLoad()

    DispatchQueue.main.async {
//      // CUSTOM FOR DENVER, potentially use when no GPS is found.
//      let cameraOptions = CameraOptions(
//        center: CLLocationCoordinate2D( latitude: 39.753580116073685, longitude: -105.04056378182935),
//        zoom: 15.5
//      )

      let followPuckViewportState = self.mapView.viewport.makeFollowPuckViewportState(
        options: FollowPuckViewportStateOptions(
          padding: UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0),
          // Intentionally avoid bearing sync in search mode.
          bearing: .none,
          pitch: 0
        )
      )
      self.mapView.viewport.transition(to: followPuckViewportState) { _ in
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
  func categorySearchResultsReceived(category _: SearchCategory, results: [SearchResult]) {
    showAnnotations(results: results)
  }

  func searchResultSelected(_ searchResult: SearchResult) {
    showAnnotation(searchResult)

    if let currentLocation = mapboxControllers.searchController.configuration.locationProvider?.currentLocation() {
      getOSRMDirections(startPoint: currentLocation, endPoint: searchResult.coordinate)
    } else {
      print("ERROR: No user location found")
    }
  }

  func userFavoriteSelected(_ userFavorite: FavoriteRecord) {
    showAnnotation(userFavorite)
  }
}

extension SimpleUISearchViewControllerInternal {
  func getOSRMDirections(startPoint: CLLocationCoordinate2D, endPoint: CLLocationCoordinate2D) {
    // BIKESTREETS DIRECTIONS

    //  206.189.205.9/route/v1/driving/-105.03667831420898,39.745358641453315;-105.04232168197632,39.74052436233521?overview=false&alternatives=true&steps=true&annotations=true
    var components = URLComponents()
    components.scheme = "http"
    components.host = "206.189.205.9"
    components.percentEncodedPath = "/route/v1/driving/\(startPoint.longitude),\(startPoint.latitude);\(endPoint.longitude),\(endPoint.latitude)"

    print("""
    [MATTROB] OSRM REQUEST:

    \(components.string ?? "ERROR EMPTY")

    """)

    components.queryItems = [
      URLQueryItem(name: "overview", value: "full"),
      URLQueryItem(name: "geometries", value: "geojson"),
      URLQueryItem(name: "alternatives", value: "true"),
      URLQueryItem(name: "steps", value: "true"),
      URLQueryItem(name: "annotations", value: "true"),
    ]

    let session = URLSession.shared
    let request = URLRequest(url: components.url!)
    let task = session.dataTask(with: request) { data, _, error in

      if let error {
        // Handle HTTP request error
        print(error)
      } else if let data {
        // Handle HTTP request response
        print(data)
        let responseObject = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

        let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

        //          print(String(decoding: jsonData!, as: UTF8.self))

        //          print(responseObject)

        do {
          let result = try JSONDecoder().decode(RouteServiceResponse.self, from: jsonData!)
          print(result)

          if let coordinates = result.routes.first?.geometry.coordinates {
            var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)
            polylineAnnotationOSM.lineColor = .init(.red)
            polylineAnnotationOSM.lineWidth = 4
            self.polylineAnnotationManager.annotations = [polylineAnnotationOSM]

            // Zoom map to show entire route
            self.cameraToCoordinates(coordinates)

            let jsonCoordinatesData = try? JSONSerialization.data(
              withJSONObject: coordinates.map { [$0.longitude, $0.latitude] },
              options: .prettyPrinted
            )
            print("""
            [MATTROB] OSRM RESPONSE:

            \(String(decoding: jsonCoordinatesData!, as: UTF8.self))

            """)
          } else {
            self.polylineAnnotationManager.annotations = []
          }
        } catch {
          print(error)
        }
      } else {
        // Handle unexpected error
        print("ELSE CASE")
      }
    }
    task.resume()
  }
}
