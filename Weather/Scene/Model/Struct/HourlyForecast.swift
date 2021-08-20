//
//  HoursForecast.swift
//  Weather
//
//  Created by Володя on 14.07.2021.
//

import Foundation

struct HourlyForecast: Codable {
    var lat: Double = 0.0
    var lon: Double = 0.0
    var timezone: String = ""
    var timezoneOffset: Int = 0
    var hourly: [Hourly] = []

    enum CodingKeys: String, CodingKey {
        case lat
        case lon
        case timezone
        case timezoneOffset = "timezone_offset"
        case hourly
    }
}

struct Hourly: Codable {
    var dt: Int = 0
    var temp: Double = 0.0
    var clouds: Int = 0
    var windSpeed: Double = 0.0
    var weather: [Weather] = []

    enum CodingKeys: String, CodingKey {
        case dt
        case temp
        case clouds
        case windSpeed = "wind_speed"
        case weather
    }
}

struct Weather: Codable {
    var id: Int = 0
    var main: String = ""
    var description: String = ""
    var icon: String = ""

    enum CodingKeys: String, CodingKey {
        case id
        case main
        case description
        case icon
    }
}
