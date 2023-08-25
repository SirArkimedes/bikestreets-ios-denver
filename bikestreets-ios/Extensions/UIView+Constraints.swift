//
//  UIView+Constraints.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/7/23.
//

import Foundation
import UIKit

extension UIView {
  func matchAutolayoutSize(_ view: UIView, insets: UIEdgeInsets = .zero) {
    NSLayoutConstraint.activate([
      view.leftAnchor.constraint(equalTo: leftAnchor, constant: insets.left),
      view.rightAnchor.constraint(equalTo: rightAnchor, constant: insets.right),
      view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
      view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: insets.bottom),
    ])
  }
}
