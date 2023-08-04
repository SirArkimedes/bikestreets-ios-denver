//
//  SearchViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import MapKit
import UIKit

final class SearchViewController: UIViewController {
  private let stateManager: StateManager
  private let searchViewController = LocationSearchTableViewController()
  var delegate: LocationSearchDelegate?

  init(stateManager: StateManager) {
    self.stateManager = stateManager
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    searchViewController.delegate = self

    view.backgroundColor = .white

    let vamosLabel = UILabel()
    vamosLabel.translatesAutoresizingMaskIntoConstraints = false
    vamosLabel.text = "Find a route with VAMOS"
    view.addSubview(vamosLabel)

    NSLayoutConstraint.activate([
      vamosLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
      vamosLabel.leftAnchor.constraint(equalTo: view.leftAnchor),
      vamosLabel.rightAnchor.constraint(equalTo: view.rightAnchor),
      vamosLabel.heightAnchor.constraint(equalToConstant: 40),
    ])

    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8
    // This makes it inset below the navigation bar on the sheet for now.
    stackView.isLayoutMarginsRelativeArrangement = true
    view.addSubview(stackView)
    NSLayoutConstraint.activate([
      vamosLabel.bottomAnchor.constraint(equalTo: stackView.topAnchor),
      view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
      view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
      view.rightAnchor.constraint(equalTo: stackView.rightAnchor),
    ])

    searchViewController.willMove(toParent: self)
    addChild(searchViewController)

    let searchBarHolder = UIView()
    searchBarHolder.translatesAutoresizingMaskIntoConstraints = false
    searchBarHolder.addSubview(searchViewController.searchController.searchBar)
    NSLayoutConstraint.activate([
      searchBarHolder.topAnchor.constraint(equalTo: searchViewController.searchController.searchBar.topAnchor),
      searchBarHolder.heightAnchor.constraint(equalToConstant: 56),
      searchBarHolder.leftAnchor.constraint(equalTo: searchViewController.searchController.searchBar.leftAnchor),
      searchBarHolder.rightAnchor.constraint(equalTo: searchViewController.searchController.searchBar.rightAnchor),
    ])
    stackView.addArrangedSubview(searchBarHolder)

    stackView.addArrangedSubview(searchViewController.view)

    searchViewController.didMove(toParent: self)
  }
}

// MARK: - LocationSearchDelegate

extension SearchViewController: LocationSearchDelegate {
  func didSelect(mapItem: MKMapItem) {
    delegate?.didSelect(mapItem: mapItem)

    // Consider searching to be done.
    searchViewController.searchController.searchBar.endEditing(true)
    searchViewController.searchController.isActive = false

    let directionPreviewViewController = DirectionPreviewViewController(stateManager: stateManager)
    navigationController?.pushViewController(directionPreviewViewController, animated: true)
  }
}
