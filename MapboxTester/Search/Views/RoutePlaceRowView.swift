//
//  RoutePlaceRowView.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/7/23.
//

import Foundation
import UIKit

private extension UIView {
  convenience init(insetView child: UIView, insets: UIEdgeInsets) {
    self.init(frame: .zero)

    translatesAutoresizingMaskIntoConstraints = false
    addSubview(child)
    matchAutolayoutSize(child, insets: insets)
  }
}

final class RoutePlaceRowView: UIStackView {
  init(destinationName: String) {
    let fromView = UILabel()
    fromView.translatesAutoresizingMaskIntoConstraints = false
    fromView.text = "From\nCurrent Location"
    fromView.numberOfLines = 0

    let toView = UILabel()
    toView.translatesAutoresizingMaskIntoConstraints = false
    toView.text = "To\n\(destinationName)"
    toView.numberOfLines = 0

    super.init(frame: .zero)

    addArrangedSubview(.init(insetView: fromView, insets: .init(top: 0, left: 16, bottom: 0, right: 16)))
    addArrangedSubview(.init(insetView: toView, insets: .init(top: 0, left: 16, bottom: 0, right: 16)))

    axis = .vertical
    spacing = 16

    layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    isLayoutMarginsRelativeArrangement = true
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
