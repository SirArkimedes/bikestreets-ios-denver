//
//  DirectionPreviewViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import UIKit

final class DirectionPreviewViewController: UIViewController {
  private let scrollView: UIScrollView = {
    let scrollView = UIScrollView()
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    return scrollView
  }()
  private let stateManager: StateManager

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
    titleLabel.font = .preferredFont(forTextStyle: .largeTitle, weight: .bold)

    let titleContainer = UIView()
    titleContainer.addSubview(titleLabel)
    titleContainer.matchAutolayoutSize(titleLabel)

    let placesStackView = RoutePlaceRowView(originName: originName, destinationName: destinationName)
    placesStackView.layer.cornerRadius = 16
    placesStackView.clipsToBounds = true
    placesStackView.backgroundColor = .tertiarySystemBackground

    let routesLabel = UILabel()
    routesLabel.translatesAutoresizingMaskIntoConstraints = false
    routesLabel.text = "Routes"
    routesLabel.font = .preferredFont(forTextStyle: .title2, weight: .bold)

    let possibleRoutesView = PossibleRoutesView(stateManager: stateManager)
    possibleRoutesView.delegate = self
    possibleRoutesView.layer.cornerRadius = 16
    possibleRoutesView.clipsToBounds = true
    possibleRoutesView.backgroundColor = .tertiarySystemBackground

    let spacerView = UIView()
    spacerView.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      spacerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 16)
    ])

    let stackView = UIStackView(arrangedSubviews: [
      titleContainer,
      placesStackView,
      routesLabel,
      possibleRoutesView,
      spacerView
    ])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 16

    scrollView.addSubview(stackView)

    view.addSubview(scrollView)
    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      stackView.topAnchor.constraint(equalTo: view.topAnchor, constant: 16),
      stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
    ])
    view.matchAutolayoutSize(scrollView)

    stateManager.add(listener: self)
  }

  // MARK: - Helpers

  private var originName: String {
    switch stateManager.state {
    case .previewDirections(let preview):
      return preview.request.origin.name
    case .requestingRoutes(let request):
      return request.origin.name
    default:
      fatalError("Unsupported state")
    }
  }

  private var destinationName: String {
    switch stateManager.state {
    case .previewDirections(let preview):
      return preview.request.destination.name
    case .requestingRoutes(let request):
      return request.destination.name
    default:
      fatalError("Unsupported state")
    }
  }
}

// MARK: - StateListener

extension DirectionPreviewViewController: StateListener {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State) {
//    if case .requestingRoutes = oldState, case .previewDirections(let preview) = newState {
//      currentPreview = preview
//    }
  }
}

// MARK: - RouteSelectable

extension DirectionPreviewViewController: RouteSelectable {
  func didSelect(route: Route) {
    // TODO: Add route selection support.
  }

  func didStart(route: Route) {
    switch stateManager.state {
    case .previewDirections(let preview):
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
