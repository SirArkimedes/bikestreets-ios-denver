//
//  MapboxTesterApp.swift
//  MapboxTester
//
//  Created by Matt Robinson on 6/12/23.
//

import SwiftUI

@main
struct MapboxTesterApp: App {
  var body: some Scene {
    WindowGroup {
      // Enable DEBUG view
      // ContentView()
      SimpleUISearchViewController().ignoresSafeArea()
    }
  }
}
