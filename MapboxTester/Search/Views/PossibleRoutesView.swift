//
//  PossibleRoutesView.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/8/23.
//

import Foundation
import UIKit

protocol RouteSelectable: AnyObject {
  func didSelect(route: Route)
  func didStart(route: Route)
}

final class PossibleRoutesView: UIStackView {
  weak var delegate: RouteSelectable?
  private let stateManager: StateManager
  private let distanceFormatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitOptions = .naturalScale
    return formatter
  }()

  init(stateManager: StateManager) {
    self.stateManager = stateManager
    super.init(frame: .zero)

    stateManager.add(listener: self)

    configureSubviews()

    axis = .vertical
    spacing = 16

    layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    isLayoutMarginsRelativeArrangement = true
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: - Helpers

  private var routes: [Route] {
    switch stateManager.state {
    case .previewDirections(let preview):
      return preview.response.routes
    case .requestingRoutes:
      return []
    default:
      fatalError("Unsupported state")
    }
  }

  private func configureSubviews() {
    // Clean up past arranged subviews
    for subview in arrangedSubviews {
      removeArrangedSubview(subview)
    }

    for (index, route) in routes.enumerated() {
      let titleLabel = UILabel()
      titleLabel.translatesAutoresizingMaskIntoConstraints = false
      titleLabel.text = "Route \(index + 1)"
      titleLabel.font = .preferredFont(forTextStyle: .body, weight: .bold)

      let distanceLabel = UILabel()
      distanceLabel.translatesAutoresizingMaskIntoConstraints = false
      distanceLabel.text = distanceString(for: route.distance)
      distanceLabel.font = .preferredFont(forTextStyle: .callout)

      let leftInsetView = UIView()
      leftInsetView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        leftInsetView.widthAnchor.constraint(equalToConstant: 16),
      ])

      let labelStack = UIStackView(arrangedSubviews: [titleLabel, distanceLabel])
      labelStack.axis = .vertical
      labelStack.spacing = 4

      let spacerView = UIView()
      spacerView.translatesAutoresizingMaskIntoConstraints = false

      let button = UIButton(type: .roundedRect)
      button.backgroundColor = .systemGreen
      button.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        button.heightAnchor.constraint(equalToConstant: 60),
        button.widthAnchor.constraint(equalToConstant: 60),
      ])
      button.layer.cornerRadius = 8
      button.clipsToBounds = true
      button.setTitle("GO", for: .normal)
      button.setTitleColor(.white, for: .normal)
      button.titleLabel?.font = .preferredFont(forTextStyle: .body, weight: .bold)
      // Used to identify the tapped on route index.
      button.tag = index
      button.addTarget(self, action: #selector(didTapRouteGo(sender:)), for: .touchUpInside)

      let rightInsetView = UIView()
      rightInsetView.translatesAutoresizingMaskIntoConstraints = false
      NSLayoutConstraint.activate([
        rightInsetView.widthAnchor.constraint(equalToConstant: 16),
      ])

      let routeStack = UIStackView(arrangedSubviews: [
        leftInsetView,
        labelStack,
        spacerView,
        button,
        rightInsetView
      ])
      routeStack.axis = .horizontal
      routeStack.spacing = 0
      routeStack.alignment = .center

      // Used to identify the tapped on route index.
      routeStack.tag = index
      // Add support for tapping on the route stack.
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapRouteStack(recognizer:)))
      routeStack.addGestureRecognizer(tapGestureRecognizer)

      addArrangedSubview(
        routeStack
      )
    }
  }

  // MARK: - Data Formatting

  private func distanceString(for distance: Double) -> String {
    let measurement = Measurement(value: distance, unit: UnitLength.meters)
    return distanceFormatter.string(from: measurement)
  }

  // MARK: - Tap Handling

  @objc
  private func didTapRouteStack(recognizer: UITapGestureRecognizer) {
    guard let routeIndex = recognizer.view?.tag else {
      return
    }
    delegate?.didSelect(route: routes[routeIndex])
  }

  @objc
  private func didTapRouteGo(sender: UIButton) {
    let routeIndex = sender.tag
    delegate?.didStart(route: routes[routeIndex])
  }
}

extension PossibleRoutesView: StateListener {
  func didUpdate(from oldState: StateManager.State, to newState: StateManager.State) {
    switch newState {
    case .requestingRoutes, .previewDirections:
      configureSubviews()
    default: break
    }
  }
}
