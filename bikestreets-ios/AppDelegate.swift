//
//  AppDelegate.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/3/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?

  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let mainViewController = DefaultMapsViewController()

    window = UIWindow(frame: UIScreen.main.bounds)
    window?.rootViewController = mainViewController
    window?.makeKeyAndVisible()

    DispatchQueue.main.async {
      try? self.cleanUpDebugFiles()
    }

    return true
  }

  // MARK: -- Clean Up

  private func cleanUpDebugFiles() throws {
    try DebugLogHandler().files().forEach { (path, entry) in
      // Clean up if more than a week old.
      if entry.date.timeIntervalSinceNow < -60*60*24*7 {
        try FileManager.default.removeItem(at: path)
      }
    }
  }
}
