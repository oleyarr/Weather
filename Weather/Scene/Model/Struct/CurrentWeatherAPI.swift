//
//  CurrentWeatherAPI.swift
//  Weather
//
//  Created by Володя on 11.07.2021.
//

import Foundation

struct CurrentWeatherAPI: Codable {
    var coord: Coord
    var weather: [WeatherDetails]
    var base: String
    var main: Main
    var visibility: Double
    var wind: Wind
    var clouds: Clouds
    var timeUTC: Int
    var timezone: Int
    var dt: Int
    var name: String
    var cod: Int
}

struct Coord: Codable {
    var lon: Double
    var lat: Double
}

struct WeatherDetails: Codable {
    var dt: Int
    var main: String
    var description: String
    var icon: String
}

struct Main: Codable {
    var temp: Double
    var feelsLike: Double
    var tempMin: Double
    var tempMax: Double
    var pressure: Int
    var humidity: Int
    var seaLevel: Int
    var grndLevel: Int
}

struct Wind: Codable {
    var speed: Double
    var deg: Double
    var gust: Double
}

struct Clouds: Codable {
    var all: Double
}
