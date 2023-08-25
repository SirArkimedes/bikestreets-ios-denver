//
//  RoutePlaceRowView.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/7/23.
//

import Foundation
import UIKit

final class RoutePlaceRowView: UIStackView {
  init(originName: String, destinationName: String) {
    let fromTitle = UILabel()
    fromTitle.translatesAutoresizingMaskIntoConstraints = false
    fromTitle.text = "From"
    fromTitle.font = .preferredFont(forTextStyle: .body, weight: .bold)

    let fromName = UILabel()
    fromName.translatesAutoresizingMaskIntoConstraints = false
    fromName.text = originName
    fromName.font = .preferredFont(forTextStyle: .body)

    let toTitle = UILabel()
    toTitle.translatesAutoresizingMaskIntoConstraints = false
    toTitle.text = "To"
    toTitle.font = .preferredFont(forTextStyle: .body, weight: .bold)

    let toName = UILabel()
    toName.translatesAutoresizingMaskIntoConstraints = false
    toName.text = destinationName
    toName.font = .preferredFont(forTextStyle: .body)

    super.init(frame: .zero)

    addArrangedSubview(.init(insetView: fromTitle, insets: .init(top: 0, left: 16, bottom: 0, right: 16)))
    addArrangedSubview(.init(insetView: fromName, insets: .init(top: 0, left: 16, bottom: 0, right: 16)))
    addArrangedSubview(.init(insetView: toTitle, insets: .init(top: 0, left: 16, bottom: 0, right: 16)))
    addArrangedSubview(.init(insetView: toName, insets: .init(top: 0, left: 16, bottom: 0, right: 16)))

    axis = .vertical
    spacing = 8

    layoutMargins = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
    isLayoutMarginsRelativeArrangement = true
  }

  required init(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
