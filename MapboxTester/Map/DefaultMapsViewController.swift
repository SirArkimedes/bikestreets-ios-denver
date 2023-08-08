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

final class DefaultMapsViewController: MapsViewController {
  private let searchViewController: SearchViewController
  private let sheetHeightInspectionView = SizeTrackingView()

  private let stateManager = StateManager()
  private let screenManager: ScreenManager

  /// Camera bottom inset based on the presented sheet height.
  private var cameraBottomInset: CGFloat {
    (sheetHeightInspectionView.lastFrameBroadcast?.height ?? 0) + 24
  }

  init() {
    screenManager = ScreenManager(stateManager: stateManager)

    let searchViewController = SearchViewController(stateManager: stateManager)
    searchViewController.sheetPresentationController?.configure()
    self.searchViewController = searchViewController

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

    // Set initial map style.
    updateMapStyle()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    // Start with map in Denver.
    let cameraOptions = CameraOptions(
      center: .denver,
      zoom: 15.5
    )
    mapView.mapboxMap.setCamera(to: cameraOptions)

    // Set up sheet height tracker.
    view.superview!.addSubview(self.sheetHeightInspectionView)
    NSLayoutConstraint.activate([
      sheetHeightInspectionView.leftAnchor.constraint(equalTo: view.leftAnchor),
      sheetHeightInspectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
      sheetHeightInspectionView.rightAnchor.constraint(equalTo: view.rightAnchor),
      // Height is tracked on a per-sheet basis.
    ])
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)

    searchViewController.sheetPresentationController?.delegate = self
    present(searchViewController, animated: true) {
      self.inspectHeight(of: self.searchViewController)
    }
  }

  private var heightInspectionConstraint: NSLayoutConstraint?
  private func inspectHeight(of viewController: UIViewController) {
    heightInspectionConstraint?.isActive = false

    heightInspectionConstraint = sheetHeightInspectionView.topAnchor.constraint(equalTo: viewController.view.topAnchor)
    heightInspectionConstraint?.isActive = true
  }

  // MARK: - Map Movement

  // TODO: Update location to Denver if no location is accessible.
  private func updateMapCameraForInitialState(bottomInset: CGFloat) {
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

  private func updateMapCameraForRoutePreview(preview: StateManager.DirectionsPreview) {
    // Zoom to show a single route or all routes.
    let cameraTopInset: CGFloat = self.view.safeAreaInsets.top

    // TODO: Add handling for "possible routes" vs. just the selected route.
    // preview.response.routes.map(\.geometry.coordinates).flatMap { $0 }
    let coordinates: [CLLocationCoordinate2D] = preview.selectedRoute.geometry.coordinates

    let overviewViewportState = mapView.viewport.makeOverviewViewportState(
      options: .init(
        geometry: LineString(coordinates),
        padding: .init(top: cameraTopInset, left: 24, bottom: cameraBottomInset, right: 24)
      )
    )

    mapView.viewport.transition(to: overviewViewportState) { _ in
      // the transition has been completed with a flag indicating whether the transition succeeded
    }
  }

  private func updateMapCameraForRouting(bottomInset: CGFloat) {
    let followPuckViewportState = mapView.viewport.makeFollowPuckViewportState(
      options: FollowPuckViewportStateOptions(
        padding: UIEdgeInsets(top: 200, left: 0, bottom: bottomInset, right: 0),
        bearing: .heading,
        pitch: 0
      )
    )
    mapView.viewport.transition(to: followPuckViewportState) { _ in
      // the transition has been completed with a flag indicating whether the transition succeeded
    }
  }

  private func updateMapAnnotations(selectedRoute: Route, potentialRoutes: [Route]) {
    polylineAnnotationManager.annotations = [
      .activeRouteAnnotation(coordinates: selectedRoute.geometry.coordinates)
    ] + potentialRoutes.map {
      .potentialRouteAnnotation(coordinates: $0.geometry.coordinates)
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
          if let firstRoute = result.routes.first {
            // On initial state update, assume first route is selected.
            self.stateManager.state = .previewDirections(
              preview: .init(request: request, response: result, selectedRoute: firstRoute)
            )
          } else {
            // TODO: Improve the state when a route is requested but returns no options.
            self.stateManager.state = .initial
          }
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
    case .initial:
      // Assume routing was canceled. Restart from the initial launch state.
      if presentedViewController != self.searchViewController {
        self.searchViewController.sheetPresentationController?.configure()
        dismiss(animated: true) {
          self.searchViewController.sheetPresentationController?.delegate = self
          self.present(self.searchViewController, animated: true)
        }
      }

      // Adjust camera.
      updateMapCameraForInitialState(bottomInset: cameraBottomInset)
    case .requestingRoutes(let request):
      // Potentially show destination on map
      // showAnnotation(.init(item: mapItem), cameraShouldFollow: false)
      // Potentially shift to smaller sheet presentation
      // sheetNavigationController.sheetPresentationController?.selectedDetentIdentifier = UISheetPresentationController.Detent.small().identifier
      requestDirections(request: request)
    case .previewDirections(let preview):
      updateMapCameraForRoutePreview(preview: preview)
      updateMapAnnotations(selectedRoute: preview.selectedRoute, potentialRoutes: preview.response.routes)
    case .routing(let routing):
      // Dismiss initial sheet, show routing sheet.
      dismiss(animated: true) {
        let viewController = RoutingViewController(stateManager: self.stateManager)
        viewController.sheetPresentationController?.configure(detents: [.tiny()], largestUndimmedDetentIdentifier: .tiny)
        viewController.sheetPresentationController?.delegate = self
        self.present(viewController, animated: true)
      }

      // Update route polyline display.
      updateMapCameraForRouting(bottomInset: cameraBottomInset)
      updateMapAnnotations(selectedRoute: routing.selectedRoute, potentialRoutes: [])
    }

    // Adjust sheet sizing constraint to top-most presented VC. This is a less
    // than ideal way to ensure we get the top-most presented VC _after_ it has
    // been presented based on a state change. This could be refactored into
    // a more centralized approach to unify the handling of push/pop while
    // keeping internal catalog of the top-most VC.
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
      var topController = self.presentedViewController
      while let newTopController = topController?.presentedViewController {
        topController = newTopController
      }

      if let topController {
        self.inspectHeight(of: topController)
      }
    }
  }
}

// MARK: - SizeTrackingListener

extension DefaultMapsViewController: SizeTrackingListener {
  func didChangeFrame(_ view: UIView, frame: CGRect) {
    // TODO: Make this smarter. For example, don't resize in the case where the sheet detent is large.
    switch stateManager.state {
    case .initial:
      updateMapCameraForInitialState(bottomInset: frame.height)
    case .previewDirections(let preview):
      updateMapCameraForRoutePreview(preview: preview)
    case .routing:
      updateMapCameraForRouting(bottomInset: frame.height)
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
        request: .init(
          start: currentLocation.coordinate,
          end: mapItem.placemark.coordinate,
          destinationItem: mapItem
        )
      )
    } else {
      fatalError("No user location found")
    }
  }
}

// MARK: - UISheetPresentationControllerDelegate

extension DefaultMapsViewController: UISheetPresentationControllerDelegate {
  func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
    return false
  }
}

// MARK: -- Dark Mode

extension DefaultMapsViewController {
  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)

    if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
      updateMapStyle()
    }
  }

  private func updateMapStyle() {
    if traitCollection.userInterfaceStyle == .dark {
      mapView.mapboxMap.loadStyleURI(StyleURI.dark)
    } else {
      mapView.mapboxMap.loadStyleURI(StyleURI.streets)
    }
  }
}
