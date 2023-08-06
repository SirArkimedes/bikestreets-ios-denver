//
//  DirectionPreviewViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import UIKit

final class DirectionPreviewViewController: UITableViewController {
  private let stateManager: StateManager
  private let distanceFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .naturalScale
    return formatter
  }()

  private var currentPreview: StateManager.DirectionsPreview? {
    didSet {
      tableView.reloadData()
    }
  }

  init(stateManager: StateManager) {
    self.stateManager = stateManager
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    stateManager.add(listener: self)
  }
}

// MARK: - StateListener

extension DirectionPreviewViewController: StateListener {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State) {
    if case .requestingRoutes = oldState, case .previewDirections(let preview) = newState {
      currentPreview = preview
    }
  }
}

// MARK: - UITableView

extension DirectionPreviewViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentPreview?.response.routes.count ?? 0
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let response = currentPreview?.response else {
      fatalError("Unable to find response for directions view")
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
    let route = response.routes[indexPath.row]
    cell.textLabel?.text = "Option \(indexPath.row + 1)"
    cell.detailTextLabel?.text = distanceString(for: route.distance)
    return cell
  }

  private func distanceString(for distance: Double) -> String {
    let measurement = Measurement(value: distance, unit: UnitLength.meters)
    return distanceFormatter.string(from: measurement)
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    switch stateManager.state {
    case .previewDirections(let preview):
      let route = preview.response.routes[indexPath.row]

      stateManager.state = .routing(routing: .init(
        request: preview.request,
        response: preview.response,
        selectedRoute: route
      ))
    default:
      fatalError("State must be preview directions when route is selected")
    }
  }
}
