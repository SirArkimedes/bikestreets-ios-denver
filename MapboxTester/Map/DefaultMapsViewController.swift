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

  private let stateManager = StateManager()

  init() {
    let viewController = SearchViewController(stateManager: stateManager)
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
    stateManager.add(listener: self)
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

  // MARK: - Map Movement

  // TODO: Update location to Denver if no location is accessible.
  private func updatePuckViewportState(bottomInset: CGFloat) {
    let followPuckViewportState = mapView.viewport.makeFollowPuckViewportState(
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

  private func updateMapViewForRoutes(preview: StateManager.DirectionsPreview) {
    if preview.response.routes.count > 0 {
      polylineAnnotationManager.annotations = preview.response.routes.map { route in
        if route == preview.selectedRoute {
          return .activeRouteAnnotation(coordinates: route.geometry.coordinates)
        } else {
          return .potentialRouteAnnotation(coordinates: route.geometry.coordinates)
        }
      }

      // Zoom to show a single route or all routes.
      let cameraTopInset: CGFloat = self.view.safeAreaInsets.top
      let cameraBottomInset: CGFloat = (self.sheetHeightInspectionView.lastFrameBroadcast?.height ?? 0) + 24
      let coordinates: [CLLocationCoordinate2D] = {
        if let route = preview.selectedRoute {
          return route.geometry.coordinates
        } else {
          return preview.response.routes.map(\.geometry.coordinates).flatMap { $0 }
        }
      }()

      let overviewViewportState = mapView.viewport.makeOverviewViewportState(
        options: .init(
          geometry: LineString(coordinates),
          padding: .init(top: cameraTopInset, left: 24, bottom: cameraBottomInset, right: 24)
        )
      )

      mapView.viewport.transition(to: overviewViewportState) { _ in
        // the transition has been completed with a flag indicating whether the transition succeeded
      }

    } else {
      polylineAnnotationManager.annotations = []
    }
  }

  // MARK: - State Handling

  private func requestDirections(request: StateManager.RouteRequest) {
    RouteRequester.getOSRMDirections(
      startPoint: request.start,
      endPoint: request.end
    ) { result in
      switch result {
      case .success(let result):
        DispatchQueue.main.async {
          // On initial state update, assume first route is selected.
          self.stateManager.state = .previewDirections(
            preview: .init(request: request, response: result, selectedRoute: result.routes.first)
          )
        }
      case .failure(let error):
        // TODO: Handle route request errors.
        print(error)
      }
    }
  }
}

// MARK: - State Management

extension DefaultMapsViewController: StateListener {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State) {
    switch newState {
    case .initial: break
    case .requestingRoutes(let request):
      // Potentially show destination on map
      // showAnnotation(.init(item: mapItem), cameraShouldFollow: false)
      // Potentially shift to smaller sheet presentation
      // sheetNavigationController.sheetPresentationController?.selectedDetentIdentifier = UISheetPresentationController.Detent.small().identifier
      requestDirections(request: request)
    case .previewDirections(let preview):
      updateMapViewForRoutes(preview: preview)
    case .routing: break
    }
  }
}

// MARK: - SizeTrackingListener

extension DefaultMapsViewController: SizeTrackingListener {
  func didChangeFrame(_ view: UIView, frame: CGRect) {
    // TODO: Make this smarter. For example, don't resize in the case where the sheet detent is large.
    switch stateManager.state {
    case .initial, .routing:
      updatePuckViewportState(bottomInset: frame.height)
    case .previewDirections(let preview):
      updateMapViewForRoutes(preview: preview)
    default:
      break
    }
  }
}

// MARK: - LocationSearchDelegate

extension DefaultMapsViewController: LocationSearchDelegate {
  func didSelect(mapItem: MKMapItem) {
    if let currentLocation = mapView.location.latestLocation {
      stateManager.state = .requestingRoutes(
        request: .init(start: currentLocation.coordinate, end: mapItem.placemark.coordinate)
      )
    } else {
      print("ERROR: No user location found")
    }
  }
}
