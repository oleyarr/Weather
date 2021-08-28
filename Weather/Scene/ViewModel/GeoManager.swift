//
//  GeoManager.swift
//  Weather
//
//  Created by Володя on 27.08.2021.
//

import UIKit
import CoreLocation

class GeoManager: NSObject, CLLocationManagerDelegate {

    let geoManager = CLLocationManager()
    let viewController = ViewController()

    override init() {
        super.init()
        geoManager.desiredAccuracy = kCLLocationAccuracyBest
        geoManager.distanceFilter = 1000
        if !(geoManager.authorizationStatus == .authorizedWhenInUse
                || geoManager.authorizationStatus == .authorizedAlways) {
            geoManager.requestAlwaysAuthorization()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        viewController.savedCurrentLocation = (locations[0].coordinate.latitude, locations[0].coordinate.longitude)
        viewController.getCurrentLocationHourlyForecast()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch geoManager.authorizationStatus {
        case .denied, .notDetermined, .restricted:
            return
        default:
            geoManager.startUpdatingLocation()
            viewController.currentLocationButton.setBackgroundImage(
                UIImage(systemName: "location.fill.viewfinder"),
                for: .normal
            )
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}
