//
//  DebugTableViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 9/17/23.
//

import MapboxDirections
import UIKit

struct DebugTableRow {
  let title: String
  let route: Route

  let debugJSONPath: URL

  let entry: ResponseLogEntry
}

final class DebugTableViewController: UITableViewController {
  private let entries: [DebugTableRow]
  init(entries: [(path: URL, entry: ResponseLogEntry)]) {
    let dateFormatter: DateFormatter = {
      let formatter = DateFormatter()
      formatter.dateFormat = "yyyy-MM-d HH:mm:ss"
      return formatter
    }()

    self.entries = entries.sorted(by: { row1, row2 in
      return row1.entry.date.timeIntervalSince1970 > row2.entry.date.timeIntervalSince1970
    }).flatMap { entry in
      let routes = entry.entry.response.routes ?? []
      return routes.enumerated().map { (index, route) in
        let titleDateString = dateFormatter.string(from: entry.entry.date)
        return DebugTableRow(
          title: "\(titleDateString) - Route \(index + 1)",
          route: route,
          debugJSONPath: entry.path,
          entry: entry.entry
        )
      }
    }
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    tableView.register(DebugTableViewCell.self, forCellReuseIdentifier: "debug-cell")
    tableView.rowHeight = 200
  }

  // MARK: - UITableViewDataSource

  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return entries.count
  }

  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "debug-cell", for: indexPath) as! DebugTableViewCell
    let entry = entries[indexPath.row]

    cell.configure(
      title: entry.title,
      route: entry.route
    )

    return cell
  }

  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let entry = entries[indexPath.row]
    let filesToShare: [Any] = [entry.debugJSONPath]

    let activityViewController = UIActivityViewController(activityItems: filesToShare, applicationActivities: nil)

    present(activityViewController, animated: true, completion: nil)
  }
}
