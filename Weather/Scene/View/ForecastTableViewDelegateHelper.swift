//
//  ForecastTableViewDelegate.swift
//  Weather
//
//  Created by Володя on 21.07.2021.
//

import UIKit

class ForecastTableViewDelegateHelper: NSObject, UITableViewDelegate, UITableViewDataSource {

    var hourlyWeather = HourlyForecast()
    var viewController: ViewController

    init(viewController: ViewController) {
        self.viewController = viewController
        super.init()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return hourlyWeather.hourly.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        viewController.cityListTableView.alpha = 0
        viewController.hourlyForecastTableView.alpha = 1
        let cell = UITableViewCell()
        let dateWeather = hourlyWeather.hourly[indexPath.row].dt
        let date = Date(timeIntervalSince1970: TimeInterval(dateWeather))
        let calendar = Calendar.current
        let hour =  calendar.component(.hour, from: date)
        let day =  calendar.component(.day, from: date)
        let weekday = calendar.component(.weekday, from: date)
        var weekdayString = ""
        switch weekday {
        case 1: weekdayString = "Вс"
        case 2: weekdayString = "Пн"
        case 3: weekdayString = "Вт"
        case 4: weekdayString = "Ср"
        case 5: weekdayString = "Чт"
        case 6: weekdayString = "Пт"
        case 7: weekdayString = "Сб"
        default: weekdayString = ""
        }
        cell.textLabel?.numberOfLines = 0
        let temp = hourlyWeather.hourly[indexPath.row].temp
        var sign = ""
        switch temp.sign {
        case .minus:  sign = "-"
        case .plus:  sign = "+"
        }
        if Int(round(temp)) == 0 {
            sign = " "
        }
        let windSpeed = hourlyWeather.hourly[indexPath.row].windSpeed
        let description = hourlyWeather.hourly[indexPath.row].weather[0].description
        cell.textLabel?.text = "\(day) \(weekdayString) \(hour)ºº  " +
            "\(sign)\(Int(round(temp)))º  \(description)  ветер \(windSpeed)"
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewController.listOfLikedCitiesTableView.alpha = 0
        viewController.listOfLikedCitiesButton.isSelected = false
        viewController.listOfLikedCitiesButton.layer.shadowOpacity = 0
        viewController.hourlyForecastTableView.alpha = 1
    }
}
