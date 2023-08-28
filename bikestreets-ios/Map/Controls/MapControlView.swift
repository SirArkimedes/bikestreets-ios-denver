//
//  MapControlView.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/28/23.
//

import Foundation
import UIKit

final class MapControlView: UIView {
  init() {
    super.init(frame: .zero)

    backgroundColor = .red

    translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
      heightAnchor.constraint(equalToConstant: 150)
    ])
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
