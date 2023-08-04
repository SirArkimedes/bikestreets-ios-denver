//
//  LocationSearchTableViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import MapKit
import UIKit

protocol LocationSearchDelegate {
  func didSelect(mapItem: MKMapItem)
}

final class LocationSearchTableViewController: UITableViewController {
  var matchingItems: [MKMapItem] = []

  var delegate: LocationSearchDelegate?

  let searchController = UISearchController(searchResultsController: nil)

  override func viewDidLoad() {
    super.viewDidLoad()

    searchController.searchBar.placeholder = "Set Destination"

    searchController.searchResultsUpdater = self
    searchController.hidesNavigationBarDuringPresentation = false
  }
}

// MARK: - UITableView

extension LocationSearchTableViewController {
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return matchingItems.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
    let selectedItem = matchingItems[indexPath.row].placemark
    cell.textLabel?.text = selectedItem.name
    cell.detailTextLabel?.text = selectedItem.prettyAddress
    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    delegate?.didSelect(mapItem: matchingItems[indexPath.row])
  }
}

// MARK: - UISearchResultsUpdating

extension LocationSearchTableViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    guard let searchBarText = searchController.searchBar.text else { return }
    let request = MKLocalSearch.Request()
    request.naturalLanguageQuery = searchBarText
    // TODO: Add back region search based on viewing map region.
    // request.region = mapView.region
    let search = MKLocalSearch(request: request)
    search.start { response, _ in
      guard let response = response else {
        return
      }
      self.matchingItems = response.mapItems
      self.tableView.reloadData()
    }
  }
}
