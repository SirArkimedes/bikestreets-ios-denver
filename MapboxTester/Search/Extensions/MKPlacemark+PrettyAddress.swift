//
//  MKPlacemark+PrettyAddress.swift
//  BikeStreets
//
//  Created by Matt Robinson on 8/4/23.
//

import Foundation
import MapKit

extension MKPlacemark {
  /// Presentation ready string summarizing the address of an `MKPlacemark`.
  var prettyAddress: String {
    // put a space between "4" and "Melrose Place"
    let firstSpace = (subThoroughfare != nil && thoroughfare != nil) ? " " : ""
    // put a comma between street and city/state
    let comma = (subThoroughfare != nil || thoroughfare != nil) && (subAdministrativeArea != nil || administrativeArea != nil) ? ", " : ""
    // put a space between "Washington" and "DC"
    let secondSpace = (subAdministrativeArea != nil && administrativeArea != nil) ? " " : ""
    let addressLine = String(
      format:"%@%@%@%@%@%@%@",
      // street number
      subThoroughfare ?? "",
      firstSpace,
      // street name
      thoroughfare ?? "",
      comma,
      // city
      locality ?? "",
      secondSpace,
      // state
      administrativeArea ?? ""
    )
    return addressLine
  }
}
