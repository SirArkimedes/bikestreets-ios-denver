//
//  UIView+InsetView.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/8/23.
//

import Foundation
import UIKit

extension UIView {
  convenience init(insetView child: UIView, insets: UIEdgeInsets) {
    self.init(frame: .zero)

    translatesAutoresizingMaskIntoConstraints = false
    addSubview(child)
    matchAutolayoutSize(child, insets: insets)
  }
}
