//
//  DirectionPreviewViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import UIKit

final class DirectionPreviewViewController: UIViewController {
  private let tableView: UITableView = {
    let tableView = UITableView()
    tableView.translatesAutoresizingMaskIntoConstraints = false
    tableView.backgroundColor = .tertiarySystemBackground
    tableView.layer.cornerRadius = 16
    tableView.clipsToBounds = true
    return tableView
  }()
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

  // MARK: - View Lifecycle

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .secondarySystemBackground

    let titleLabel = UILabel()
    titleLabel.translatesAutoresizingMaskIntoConstraints = false
    titleLabel.text = "Directions"
    titleLabel.font = .preferredFont(forTextStyle: .largeTitle)

    let titleContainer = UIView()
    titleContainer.addSubview(titleLabel)
    titleContainer.matchAutolayoutSize(titleLabel)

    let placesStackView = RoutePlaceRowView(destinationName: destinationName)
    placesStackView.layer.cornerRadius = 16
    placesStackView.clipsToBounds = true
    placesStackView.backgroundColor = .tertiarySystemBackground

    let routesLabel = UILabel()
    routesLabel.translatesAutoresizingMaskIntoConstraints = false
    routesLabel.text = "Routes"
    routesLabel.font = .preferredFont(forTextStyle: .title2)

    let tableViewContainer = UIView()
    tableViewContainer.addSubview(tableView)
    tableViewContainer.matchAutolayoutSize(tableView)

    let stackView = UIStackView(arrangedSubviews: [
      titleContainer,
      placesStackView,
      routesLabel,
      tableViewContainer
    ])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 16

    let stackViewContainer = UIView()
    stackViewContainer.translatesAutoresizingMaskIntoConstraints = false
    stackViewContainer.addSubview(stackView)
    stackViewContainer.matchAutolayoutSize(stackView)

    view.addSubview(stackViewContainer)
    view.matchAutolayoutSize(stackViewContainer, insets: .init(top: 16, left: 16, bottom: 0, right: -16))

    tableView.dataSource = self
    tableView.delegate = self

    stateManager.add(listener: self)
  }

  // MARK: - Helpers

  private var destinationName: String {
    switch stateManager.state {
    case .previewDirections(let preview):
      return preview.request.destinationItem.name ?? "No Name"
    case .requestingRoutes(let request):
      return request.destinationItem.name ?? "No Name"
    default:
      fatalError("Unsupported state")
    }
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

extension DirectionPreviewViewController: UITableViewDataSource, UITableViewDelegate {
  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return currentPreview?.response.routes.count ?? 0
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    guard let response = currentPreview?.response else {
      fatalError("Unable to find response for directions view")
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
    let route = response.routes[indexPath.row]
    cell.textLabel?.text = "Option \(indexPath.row + 1)"
    cell.detailTextLabel?.text = distanceString(for: route.distance)
    cell.backgroundColor = .tertiarySystemBackground
    return cell
  }

  private func distanceString(for distance: Double) -> String {
    let measurement = Measurement(value: distance, unit: UnitLength.meters)
    return distanceFormatter.string(from: measurement)
  }

  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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
