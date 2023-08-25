//
//  UINavigationController+Sheet.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/6/23.
//

import Foundation
import UIKit

extension UINavigationController {
  convenience init(
    sheetNavigationControllerWithRootViewController rootViewController: UIViewController,
    sheetConfiguration: (UISheetPresentationController) -> Void
  ) {
    self.init(rootViewController: rootViewController)
    modalPresentationStyle = .pageSheet

    // Avoid drag gesture dismissal of the sheet.
    isModalInPresentation = true

    sheetPresentationController.map { sheetConfiguration($0) }
  }
}
