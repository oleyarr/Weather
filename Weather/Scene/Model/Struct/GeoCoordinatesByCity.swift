//
//  GeoCoordinatesByCity.swift
//  Weather
//
//  Created by Володя on 14.07.2021.
//

import Foundation

struct GeoCoordinatesByCity: Codable {
    var name: String
    var lat: Double
    var lon: Double
    var country: String
}
