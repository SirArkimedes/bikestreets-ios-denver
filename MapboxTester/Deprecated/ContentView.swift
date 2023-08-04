//
//  ContentView.swift
//  MapboxTester
//
//  Created by Matt Robinson on 6/12/23.
//

import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps
import MapboxNavigation
import SimplifySwift
import SwiftUI

final class MapTapGestureRecognizer: UITapGestureRecognizer {
  private let action: (UITapGestureRecognizer) -> Void

  init(action: @escaping (UITapGestureRecognizer) -> Void) {
    self.action = action
    super.init(target: nil, action: nil)
    // TODO: THIS CREATES A RETAIN CYCLE
    addTarget(self, action: #selector(execute))
  }

  @objc private func execute(sender: UITapGestureRecognizer) {
    action(sender)
  }
}

struct InternalMapView: UIViewRepresentable {
  func makeUIView(context _: Context) -> MapboxMaps.MapView {
    let cameraOptions = CameraOptions(
      center: CLLocationCoordinate2D(latitude: 39.753580116073685, longitude: -105.04056378182935),
      zoom: 15.5
    )

//    let accessToken = "pk.eyJ1IjoibWF0dHJvYiIsImEiOiJjajNuZjA0MHIwMDBhMndudXBzMmRjajdrIn0.l6ilrcK2Eakojkyxwkvr4A"
//    let resourceOptions = ResourceOptions()
    let myMapInitOptions = MapInitOptions(cameraOptions: cameraOptions)
    let mapView = MapView(frame: .zero, mapInitOptions: myMapInitOptions)
    mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]

    let circleAnnotationManager = mapView.annotations.makeCircleAnnotationManager()
    let polylineAnnotationManager = mapView.annotations.makePolylineAnnotationManager()

    let gestureRecognizer = MapTapGestureRecognizer { sender in
      let locationInMap = sender.location(in: mapView)
      let coordinate = mapView.mapboxMap.coordinate(for: locationInMap)

      let circleAnnotation = CircleAnnotation(centerCoordinate: coordinate)
      circleAnnotationManager.annotations.append(circleAnnotation)
    }
    mapView.addGestureRecognizer(gestureRecognizer)

    // Follow location button
    let followLocationButton = UIButton(type: .system)
    followLocationButton.setImage(UIImage(systemName: "location"), for: .normal)
    followLocationButton.backgroundColor = .white
    followLocationButton.layer.cornerRadius = 4
    followLocationButton.clipsToBounds = true
    let followLocationAction = UIAction { (_: UIAction) in
      mapView.location.options.puckType = .puck2D()
//      _ = mapView.viewport.makeFollowPuckViewportState()

      let followPuckViewportState = mapView.viewport.makeFollowPuckViewportState(
        options: FollowPuckViewportStateOptions(
          padding: UIEdgeInsets(top: 200, left: 0, bottom: 0, right: 0),
          bearing: .heading,
          pitch: 0
        ))
      mapView.viewport.transition(to: followPuckViewportState) { _ in
        // the transition has been completed with a flag indicating whether the transition succeeded
      }
    }
    followLocationButton.addAction(followLocationAction, for: .touchUpInside)

    // Generate route button
    let routeButton = UIButton(type: .system)
    routeButton.setImage(UIImage(systemName: "map"), for: .normal)
    routeButton.backgroundColor = .white
    routeButton.layer.cornerRadius = 4
    routeButton.clipsToBounds = true
    let routeAction = UIAction { (_: UIAction) in
      // BIKESTREETS DIRECTIONS
      let coordinates = circleAnnotationManager.annotations.map(\.point.coordinates)
      let startPoint = coordinates[0]
      let endPoint = coordinates[1]

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
      let task = session.dataTask(with: request) { data, response, error in

        if let error {
          // Handle HTTP request error
          print(error)
        } else if let data {
          // Handle HTTP request response
          print(data)
          let responseObject = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]

          let json = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers)
          let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

//          print(String(decoding: jsonData!, as: UTF8.self))

//          print(responseObject)

          do {
            let result = try JSONDecoder().decode(RouteServiceResponse.self, from: jsonData!)
            print(result)

            if let coordinates = result.routes.first?.geometry.coordinates {
              var polylineAnnotationOSM = PolylineAnnotation(lineCoordinates: coordinates)
              polylineAnnotationOSM.lineColor = .init(.red)
              polylineAnnotationOSM.lineWidth = 4
              polylineAnnotationManager.annotations = [polylineAnnotationOSM]

              let jsonCoordinatesData = try? JSONSerialization.data(
                withJSONObject: coordinates.map { [$0.longitude, $0.latitude] },
                options: .prettyPrinted
              )
              print("""
              [MATTROB] OSRM RESPONSE:

              \(String(decoding: jsonCoordinatesData!, as: UTF8.self))

              """)

              // Simplify polyline down to acceptable 25 coordinates.
              // Apply:
              // https://en.wikipedia.org/wiki/Ramer–Douglas–Peucker_algorithm
              let filteredCoordinates: [CLLocationCoordinate2D]?

              if coordinates.count <= 25 {
                filteredCoordinates = nil
              } else {
                filteredCoordinates = Simplify.simplify(coordinates, tolerance: 0.001, highQuality: true)

                print("""
                COORDINATE SIMPLIFICATION
                BEFORE: \(coordinates.count)
                AFTER: \(filteredCoordinates?.count ?? 0)

                """)

                let jsonCoordinatesData = try? JSONSerialization.data(
                  withJSONObject: filteredCoordinates!.map { [$0.longitude, $0.latitude] },
                  options: .prettyPrinted
                )
                print("""
                [MATTROB] OSRM FILTERED RESPONSE:

                \(String(decoding: jsonCoordinatesData!, as: UTF8.self))

                """)
              }

              var polylineAnnotationOSMFiltered: PolylineAnnotation?
              if let filteredCoordinates {
                polylineAnnotationOSMFiltered = PolylineAnnotation(lineCoordinates: filteredCoordinates)
                polylineAnnotationOSMFiltered?.lineColor = .init(.brown)
                polylineAnnotationOSMFiltered?.lineWidth = 3
              }

//              polylineAnnotationManager.annotations = [polylineAnnotationOSM, polylineAnnotationOSMFiltered].compactMap({$0})

              // MAPBOX DIRECTIONS
              let routeOptions = NavigationRouteOptions(
                coordinates: filteredCoordinates ?? coordinates,
                profileIdentifier: .cycling
              )
              routeOptions.routeShapeResolution = .full
              Directions.shared.calculate(routeOptions) { _, result in
                switch result {
                case let .failure(error):
                  print(error.localizedDescription)
                case let .success(response):
                  print("MAPBOX response: \(response)\n")

//                  print("Coords: \(response.routes![0].shape?.coordinates)")

                  if let coordinates = response.routes?.first?.shape?.coordinates {
                    let jsonCoordinatesData = try? JSONSerialization.data(
                      withJSONObject: coordinates.map { [$0.longitude, $0.latitude] },
                      options: .prettyPrinted
                    )
                    print("""
                    [MATTROB] MAPBOX COORDINATES:

                    \(String(decoding: jsonCoordinatesData!, as: UTF8.self))

                    """)

                    var polylineAnnotationMB = PolylineAnnotation(lineCoordinates: coordinates)
                    polylineAnnotationMB.lineColor = .init(.purple)
                    polylineAnnotationMB.lineWidth = 2
//                    polylineAnnotationManager.annotations = [
//                      polylineAnnotationOSM,
//                      polylineAnnotationOSMFiltered,
//                      polylineAnnotationMB
//                    ].compactMap({$0})
                  }
                }
              }
            } else {
              polylineAnnotationManager.annotations = []
            }
          } catch {
            print(error)
          }
        } else {
          // Handle unexpected error
          print("ELSE CASE")
        }
      }
      task.resume()

//
//          // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
      ////          let indexedRouteResponse = IndexedRouteResponse(routeResponse: response, routeIndex: 0)
      ////          let navigationService = MapboxNavigationService(indexedRouteResponse: indexedRouteResponse,
      ////                                                          customRoutingProvider: NavigationSettings.shared.directions,
      ////                                                          credentials: NavigationSettings.shared.directions.credentials,
      ////                                                          simulating: .onPoorGPS)
      ////          let navigationOptions = NavigationOptions(navigationService: navigationService)
      ////          strongSelf.navigationViewController = NavigationViewController(for: indexedRouteResponse,
      ////                                                                         navigationOptions: navigationOptions)
      ////          strongSelf.navigationViewController?.modalPresentationStyle = .fullScreen
      ////          strongSelf.navigationViewController?.delegate = strongSelf
      ////
      ////          strongSelf.present(strongSelf.navigationViewController!, animated: true, completion: nil)
//        }
//      }
    }
    routeButton.addAction(routeAction, for: .touchUpInside)

    // Trash coordinates button
    let trashButton = UIButton(type: .system)
    trashButton.setImage(UIImage(systemName: "trash"), for: .normal)
    trashButton.backgroundColor = .white
    trashButton.layer.cornerRadius = 4
    trashButton.clipsToBounds = true
    let trashAction = UIAction { (_: UIAction) in
      circleAnnotationManager.annotations = []
      polylineAnnotationManager.annotations = []
    }
    trashButton.addAction(trashAction, for: .touchUpInside)

    let stackView = UIStackView(arrangedSubviews: [followLocationButton, routeButton, trashButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.spacing = 4
    stackView.distribution = .fillEqually
    mapView.addSubview(stackView)
    NSLayoutConstraint.activate([
      stackView.rightAnchor.constraint(equalTo: mapView.rightAnchor, constant: -15),
      stackView.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 15),
      stackView.widthAnchor.constraint(equalToConstant: 126),
      stackView.heightAnchor.constraint(equalToConstant: 40),
    ])

    return mapView
  }

  func updateUIView(_: MapboxMaps.MapView, context _: Context) {
    // no-op
  }

  typealias UIViewType = MapView
}

struct ContentView: View {
  @State private var isShowingNavigationView = false
  @State private var isShowingSearchView = false

  var body: some View {
    NavigationView {
      VStack {
        HStack {
          Image(systemName: "globe")
            .imageScale(.large)
            .foregroundColor(.accentColor)
          Text("BikeStreets Mapbox Tester")
          Image(systemName: "globe")
            .imageScale(.large)
            .foregroundColor(.accentColor)
        }

        NavigationLink(destination: InternalMapView(), isActive: $isShowingNavigationView) { EmptyView() }
        Button("[BETA] Navigation View") {
          isShowingNavigationView = true
        }

        NavigationLink(destination: SimpleUISearchViewController().ignoresSafeArea(), isActive: $isShowingSearchView) { EmptyView() }
        Button("[BETA] Search 2") {
          isShowingSearchView = true
        }
      }
      .padding()
    }
    .navigationTitle("Navigation")
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
