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
  private let searchViewController = LocationSearchTableViewController()

  init() {
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let stackView = UIStackView()
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .vertical
    stackView.spacing = 8
    // This makes it inset below the navigation bar on the sheet for now.
    stackView.isLayoutMarginsRelativeArrangement = true
    view.addSubview(stackView)
    NSLayoutConstraint.activate([
      view.topAnchor.constraint(equalTo: stackView.topAnchor),
      view.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
      view.leftAnchor.constraint(equalTo: stackView.leftAnchor),
      view.rightAnchor.constraint(equalTo: stackView.rightAnchor),
    ])

    let vamosLabel = UILabel()
    vamosLabel.text = "Find a route with VAMOS"

    stackView.addArrangedSubview(vamosLabel)

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
