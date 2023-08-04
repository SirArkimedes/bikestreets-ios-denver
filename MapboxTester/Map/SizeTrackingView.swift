//
//  SizeTrackingView.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import UIKit

protocol SizeTrackingListener {
  func didChangeFrame(_ view: UIView, frame: CGRect)
}

final class SizeTrackingView: UIView {
  var delegate: SizeTrackingListener?

  private var lastFrameBroadcast: CGRect?

  init() {
    super.init(frame: .zero)
    isHidden = true
    translatesAutoresizingMaskIntoConstraints = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func layoutSubviews() {
    super.layoutSubviews()

    if let lastFrameBroadcast, lastFrameBroadcast != frame {
      delegate?.didChangeFrame(self, frame: frame)
    } else {
      delegate?.didChangeFrame(self, frame: frame)
    }
    lastFrameBroadcast = frame
  }
}
