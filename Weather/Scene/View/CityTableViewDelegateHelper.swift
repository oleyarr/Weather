//
//  SelectCity.swift
//  Weather
//
//  Created by Володя on 20.07.2021.
//

import UIKit

class CityTableViewDelegateHelper: NSObject, UITableViewDataSource, UITableViewDelegate {

    var viewController: ViewController
    var selectedGeoCoord = (0.0, 0.0)
    var selectedCity = (0, "", "")
    var partCityList: [CityList] = []

    init(viewController: ViewController) {
        self.viewController = viewController
        super.init()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return partCityList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = "\(partCityList[indexPath.row].name) \(partCityList[indexPath.row].country)"
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if viewController.citySearchTextField.isEditing {
            viewController.citySearchTextField.endEditing(true)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedGeoCoord = (partCityList[indexPath.row].coord.lat, partCityList[indexPath.row].coord.lon)
        selectedCity = (partCityList[indexPath.row].id,
                        partCityList[indexPath.row].name,
                        partCityList[indexPath.row].country)
        if viewController.citySearchTextField.isEditing {
            viewController.citySearchTextField.endEditing(true)
        }
        viewController.showCityForecast()
    }
}
