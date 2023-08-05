//
//  RouteRequester.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import CoreLocation
import Foundation

final class RouteRequester {
  enum RequestError: Error {
    case emptyData
    case unableToParse
  }

  static func getOSRMDirections(
    startPoint: CLLocationCoordinate2D,
    endPoint: CLLocationCoordinate2D,
    completion: @escaping (Result<RouteServiceResponse, Error>) -> Void
  ) {
    // BIKESTREETS DIRECTIONS

    //  206.189.205.9/route/v1/driving/-105.03667831420898,39.745358641453315;-105.04232168197632,39.74052436233521?overview=false&alternatives=true&steps=true&annotations=true
    var components = URLComponents()
    components.scheme = "http"
    components.host = "206.189.205.9"
    components.percentEncodedPath = "/route/v1/driving/\(startPoint.longitude),\(startPoint.latitude);\(endPoint.longitude),\(endPoint.latitude)"

    print("""
    [MATTROB] OSRM REQUEST:

    \(components.string ?? "ERROR EMPTY")

    """)

    components.queryItems = [
      URLQueryItem(name: "overview", value: "full"),
      URLQueryItem(name: "geometries", value: "geojson"),
      URLQueryItem(name: "alternatives", value: "true"),
      URLQueryItem(name: "steps", value: "true"),
      URLQueryItem(name: "annotations", value: "true"),
    ]

    let session = URLSession.shared
    let request = URLRequest(url: components.url!)
    let task = session.dataTask(with: request) { [completion] data, _, error in
      // Handle HTTP request error
      guard error == nil else {
        completion(.failure(error!))
        return
      }

      guard let data else {
        completion(.failure(RequestError.emptyData))
        return
      }

      // Handle HTTP request response
      do {
        let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
        let jsonData = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        let result = try JSONDecoder().decode(RouteServiceResponse.self, from: jsonData)
        completion(.success(result))
      } catch {
        completion(.failure(error))
      }
    }
    task.resume()
  }
}

