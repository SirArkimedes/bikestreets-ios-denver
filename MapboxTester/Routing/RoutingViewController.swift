//
//  RoutingViewController.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/6/23.
//

import Foundation
import UIKit

final class RoutingViewController: UIViewController {
  override func viewDidLoad() {
    super.viewDidLoad()

    view.backgroundColor = .white

    let stopRoutingButton = UIButton()
    stopRoutingButton.backgroundColor = .red
    stopRoutingButton.setTitle("End Route", for: .normal)
    stopRoutingButton.setTitleColor(.white, for: .normal)
    stopRoutingButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
    stopRoutingButton.layer.cornerRadius = 10
    stopRoutingButton.clipsToBounds = true

    let stackView = UIStackView(arrangedSubviews: [stopRoutingButton])
    stackView.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(stackView)
    NSLayoutConstraint.activate([
      view.safeAreaLayoutGuide.topAnchor.constraint(equalTo: stackView.topAnchor),
      view.safeAreaLayoutGuide.leadingAnchor.constraint(equalTo: stackView.leadingAnchor, constant: -16),
      view.safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: stackView.trailingAnchor, constant: 16),
      view.safeAreaLayoutGuide.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
    ])
  }
}
