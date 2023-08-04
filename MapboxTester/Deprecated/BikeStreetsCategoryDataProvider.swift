//
//  BikeStreetsCategoryDataProvider.swift
//  MapboxTester
//
//  Created by Matt Robinson on 7/14/23.
//

import Foundation
import MapboxSearchUI

public class BikeStreetsCategoryDataProvider: CategoryDataProvider {
  /// Minimal count of categories.
  public static let minCategoriesCount = 4

  /// Horizontal categories.
  public var categorySlots: [SearchCategory] {
    [.cafe, .food, .coffeeShop, .grocery]
  }

  /// Vertical list of categories.
  public var categoryList: [SearchCategory] = [
    .restaurant,
    .bar,
    .coffeeShop,
    .hotel,
    .parking,
    .busStation,
    .railwayStation,
    .shoppingMall,
    .grocery,
    .clothingStore,
    .pharmacy,
    .museum,
    .park,
    .cinema,
    .fitnessCentre,
    .nightclub,
    .atm,
    .hospital,
    .emergencyRoom,
  ]

  /// Make your default categories provider.
  public init() {}
}
