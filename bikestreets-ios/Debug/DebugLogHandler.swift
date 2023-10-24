//
//  DebugLogHandler.swift
//  BikeStreets
//
//  Created by Matt Robinson on 9/18/23.
//

import Foundation
import CoreLocation
import MapboxDirections

struct DebugLogRequest: Codable {
  let originName: String
  let originPointLatitude: Double
  let originPointLongitude: Double

  let destinationName: String
  let destinationPointLatitude: Double
  let destinationPointLongitude: Double

  init(originName: String, originPoint: CLLocationCoordinate2D, destinationName: String, destinationPoint: CLLocationCoordinate2D) {
    self.originName = originName
    self.originPointLatitude = originPoint.latitude
    self.originPointLongitude = originPoint.longitude
    self.destinationName = destinationName
    self.destinationPointLatitude = destinationPoint.latitude
    self.destinationPointLongitude = destinationPoint.longitude
  }
}

struct ResponseLogEntry: Codable {
  let date: Date

  let request: DebugLogRequest
  let response: RouteResponse
}

final class DebugLogHandler {
  private func getDocumentDirectoryPath() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
  }

  /// Migrate the models to the new Mapbox models that aren't serialized in the same was as the custom OSRM models.
  private var hasMigratedToMapboxModels: Bool {
    get { UserDefaults.standard.bool(forKey: "bikestreets.migration.debug-models.v0") }
    set { UserDefaults.standard.setValue(newValue, forKey: "bikestreets.migration.debug-models.v0") }
  }

  /// Read all debug files in directory.
  func files() throws -> [(URL, ResponseLogEntry)] {
    let path = getDocumentDirectoryPath()

    let directoryContents = try FileManager.default.contentsOfDirectory(
        at: path,
        includingPropertiesForKeys: nil
    )

    /// Complete debug model migration if necessary.
    guard hasMigratedToMapboxModels else {
      try directoryContents.forEach { path in
        try FileManager.default.removeItem(at: path)
      }
      hasMigratedToMapboxModels = true
      return []
    }

    let decoder = JSONDecoder()

    let files: [(URL, ResponseLogEntry)] = directoryContents.map { path in
      let data = try! Data(contentsOf: path)
      let entry = try! decoder.decode(ResponseLogEntry.self, from: data)

      return (path, entry)
    }

    return files
  }

  /// - Parameters:
  ///     - request: Request that created `response`.
  ///     - response: Response object from the server.
  func write(
    request: DebugLogRequest,
    response: RouteResponse
  ) throws {
    let entry = ResponseLogEntry(
      date: Date(),
      request: request,
      response: response
    )

    let encoder = JSONEncoder()
    encoder.outputFormatting = .prettyPrinted

    let data = try encoder.encode(entry)
    let dataString = String(data: data, encoding: .utf8)!

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-d@HH-mm-ss"
    let fileName = dateFormatter.string(from: entry.date) + ".json"

    var fileURL = getDocumentDirectoryPath()
      .appending(path: fileName)

    // Don't back this up
    var resourceValues = URLResourceValues()
    resourceValues.isExcludedFromBackup = true
    try? fileURL.setResourceValues(resourceValues)

    try dataString.write(to: fileURL, atomically: false, encoding: .utf8)
  }
}
