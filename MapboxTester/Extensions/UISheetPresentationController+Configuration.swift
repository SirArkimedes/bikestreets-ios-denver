//
//  UISheetPresentationController+Configuration.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/6/23.
//

import Foundation
import UIKit

extension UISheetPresentationController {
  func configure(
    detents: [UISheetPresentationController.Detent] = [.small(), .medium(), .large()],
    selectedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = .small,
    largestUndimmedDetentIdentifier: UISheetPresentationController.Detent.Identifier? = .medium
  ) {
    self.detents = detents
    self.selectedDetentIdentifier = selectedDetentIdentifier
    // Don't let the sheet dim the background content.
    self.largestUndimmedDetentIdentifier = largestUndimmedDetentIdentifier
    // Sheet needs rounded corners.
    preferredCornerRadius = 16
    // Sheet needs to show the top grabber.
    prefersGrabberVisible = true
  }
}

// MARK: - Detent Additions

extension UISheetPresentationController.Detent {

  // MARK: -- Tiny

  private static let _tiny: UISheetPresentationController.Detent = custom(identifier: .tiny, resolver: { context in
    100
  })

  static func tiny() -> UISheetPresentationController.Detent {
    return _tiny
  }


  // MARK: -- Small

  private static let _small: UISheetPresentationController.Detent = custom(identifier: .small, resolver: { context in
    175
  })
  
  static func small() -> UISheetPresentationController.Detent {
    return _small
  }
}

extension UISheetPresentationController.Detent.Identifier {
  static let tiny: UISheetPresentationController.Detent.Identifier = .init(rawValue: "tiny")
  static let small: UISheetPresentationController.Detent.Identifier = .init(rawValue: "small")
}
