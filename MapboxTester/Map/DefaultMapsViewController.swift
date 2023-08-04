//
//  DefaultMapsViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import MapboxMaps
import MapboxSearchUI
import MapKit
import SwiftUI
import UIKit

extension UISheetPresentationController.Detent {
  private static let _small: UISheetPresentationController.Detent = custom(resolver: { context in
    175
  })

  static func small() -> UISheetPresentationController.Detent {
    return _small
  }
}

final class DefaultMapsViewController: MapsViewController {
  private let searchViewController: SearchViewController
  private let sheetNavigationController: UINavigationController

  private let sheetHeightInspectionView = SizeTrackingView()

  init() {
    let viewController = SearchViewController()
    searchViewController = viewController

    sheetNavigationController = {
      let navigationController = UINavigationController(rootViewController: viewController)
      navigationController.modalPresentationStyle = .pageSheet

      // Avoid drag gesture dismissal of the sheet.
      navigationController.isModalInPresentation = true

      if let sheet = navigationController.sheetPresentationController {
        sheet.detents = [.small(), .medium(), .large()]
        // Start with smallest detent selected.
        sheet.selectedDetentIdentifier = UISheetPresentationController.Detent.small().identifier
        // Don't let the sheet dim the background content.
        sheet.largestUndimmedDetentIdentifier = .medium
        // Sheet needs rounded corners.
        sheet.preferredCornerRadius = 16
        // Sheet needs to show the top grabber.
        sheet.prefersGrabberVisible = true
      }
      return navigationController
    }()

    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    searchViewController.delegate = self
    sheetHeightInspectionView.delegate = self
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Start with map in Denver.
    let cameraOptions = CameraOptions(
      center: .denver,
      zoom: 15.5
    )
    mapView.mapboxMap.setCamera(to: cameraOptions)
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    // Show sheet.
    present(sheetNavigationController, animated: true) {
      // Set up sheet height tracker.
      self.view.superview!.addSubview(self.sheetHeightInspectionView)
      NSLayoutConstraint.activate([
        self.sheetHeightInspectionView.leftAnchor.constraint(equalTo: self.view.leftAnchor),
        self.sheetHeightInspectionView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        self.sheetHeightInspectionView.rightAnchor.constraint(equalTo: self.view.rightAnchor),
        // Ensure it tracks the height of the sheet.
        self.sheetHeightInspectionView.topAnchor.constraint(equalTo: self.sheetNavigationController.view.topAnchor)
      ])
    }
  }

  // TODO: Update location to Denver if no location is accessible.
  private func updatePuckViewportState(bottomInset: CGFloat) {
    let followPuckViewportState = self.mapView.viewport.makeFollowPuckViewportState(
      options: FollowPuckViewportStateOptions(
        padding: UIEdgeInsets(top: 200, left: 0, bottom: bottomInset, right: 0),
        // Intentionally avoid bearing sync in search mode.
        bearing: .none,
        pitch: 0
      )
    )
    mapView.viewport.transition(to: followPuckViewportState) { _ in
      // the transition has been completed with a flag indicating whether the transition succeeded
    }
  }
}

extension DefaultMapsViewController: SizeTrackingListener {
  func didChangeFrame(_ view: UIView, frame: CGRect) {
    // TODO: Make this smarter. For example, don't resize in the case where the sheet detent is large.
    self.updatePuckViewportState(bottomInset: frame.height)
  }
}

// MARK: - LocationSearchDelegate

extension DefaultMapsViewController: LocationSearchDelegate {
  func didSelect(mapItem: MKMapItem) {
    showAnnotation(.init(item: mapItem), cameraShouldFollow: false)

    if let currentLocation = mapView.location.latestLocation {
      sheetNavigationController.sheetPresentationController?.selectedDetentIdentifier = UISheetPresentationController.Detent.small().identifier

      getOSRMDirections(startPoint: currentLocation.coordinate, endPoint: mapItem.placemark.coordinate)
    } else {
      print("ERROR: No user location found")
    }
  }
}

// MARK: - OSRM Direction

extension DefaultMapsViewController {
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
            DispatchQueue.main.async {
              var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)
              polylineAnnotationOSM.lineColor = .init(.red)
              polylineAnnotationOSM.lineWidth = 4
              self.polylineAnnotationManager.annotations = [polylineAnnotationOSM]

              // Zoom map to show entire route
              let cameraTopInset: CGFloat = self.view.safeAreaInsets.top
              let cameraBottomInset: CGFloat
              if let sheetHeight = self.sheetHeightInspectionView.lastFrameBroadcast?.height {
                cameraBottomInset = sheetHeight + 20
              } else {
                cameraBottomInset = 24
              }
              self.cameraToCoordinates(coordinates, topInset: cameraTopInset, bottomInset: cameraBottomInset)
            }

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
