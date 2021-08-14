//
//  CityList.swift
//  Weather
//
//  Created by Володя on 14.07.2021.
//

import Foundation

struct CityList: Codable {
    var id: Int
    var name: String
    var state: String
    var country: String
    var coord: Coordinates
}

struct Coordinates: Codable {
    var lon: Double
    var lat: Double
}
