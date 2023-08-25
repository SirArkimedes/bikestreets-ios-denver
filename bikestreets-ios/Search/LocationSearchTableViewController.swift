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
  func mapSearchRegion() -> MKCoordinateRegion?
  func didSelect(mapItem: MKMapItem)
}

final class LocationSearchTableViewController: UITableViewController {
  /// Exists to debounce many search requests while typing. This helps avoid API overuse errors from Apple.
  private var searchTask: DispatchWorkItem?
  private var matchingItems: [MKMapItem] = []

  var delegate: LocationSearchDelegate?

  let searchController = UISearchController(searchResultsController: nil)

  override func viewDidLoad() {
    super.viewDidLoad()

    searchController.searchBar.placeholder = "Set Destination"

    searchController.searchResultsUpdater = self
    searchController.hidesNavigationBarDuringPresentation = false

    // Configure search bar visual appearance
    searchController.searchBar.barStyle = .default
    searchController.searchBar.searchBarStyle = .minimal
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
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: - UISearchResultsUpdating

extension LocationSearchTableViewController: UISearchResultsUpdating {
  func updateSearchResults(for searchController: UISearchController) {
    guard let searchBarText = searchController.searchBar.text, !searchBarText.isEmpty else { return }

    // Invalidate and reinitiate
    self.searchTask?.cancel()

    let task = DispatchWorkItem { [weak self] in
      DispatchQueue.main.async { [weak self] in
        guard let self = self else { return }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        if let searchRegion = delegate?.mapSearchRegion() {
          request.region = searchRegion
        }
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
          guard let response = response else {
            return
          }
          DispatchQueue.main.async {
            self.matchingItems = response.mapItems
            self.tableView.reloadData()
          }
        }
      }
    }

    self.searchTask = task

    // Wait 0.25 seconds before executing search to debounce typing
    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25, execute: task)
  }
}
