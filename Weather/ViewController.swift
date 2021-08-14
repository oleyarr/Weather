//  ViewController.swift
//
//  Weather
//  Createdby Володя on 11.07.2021.
//

import UIKit
import CoreLocation
import AVKit

class ViewController: UIViewController {

    @IBOutlet weak var citySearchTextField: UITextField!
    @IBOutlet weak var cityListTableView: UITableView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var hourlyForecastTableView: UITableView!
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!

    private var savedCurrentLocation = (0.0, 0.0)
    private var fullCityList: [CityList] = []
    lazy var cityTableViewDelegateHelper = CityTableViewDelegateHelper(viewController: self)
    lazy var forecastTableViewDelegateHelper = ForecastTableViewDelegateHelper(viewController: self)

    let geoManager = CLLocationManager()
    var likedLocations: [Int] = []
    private var backgroundPlayer: AVAudioPlayer?
    private var soundEffectPlayer: AVAudioPlayer?

    private var isSoundEnable = false
    private var lang = "RU"
    private var units = "Metric"
    private let userDefaults = UserDefaults.standard

    override func viewDidLoad() {
        super.viewDidLoad()

        hourlyForecastTableView.dataSource = forecastTableViewDelegateHelper
        hourlyForecastTableView.delegate = forecastTableViewDelegateHelper
        hourlyForecastTableView.alpha = 1
        cityListTableView.dataSource = cityTableViewDelegateHelper
        cityListTableView.delegate = cityTableViewDelegateHelper
        cityListTableView.alpha = 0

        citySearchTextField.placeholder = "city search".localized
        citySearchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 0))
        citySearchTextField.leftViewMode = .always

        geoManager.delegate = self
        geoManager.desiredAccuracy = kCLLocationAccuracyBest
        geoManager.distanceFilter = 1000
        if !(geoManager.authorizationStatus == .authorizedWhenInUse
                || geoManager.authorizationStatus == .authorizedAlways) {
            geoManager.requestAlwaysAuthorization()
        }

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(citySearchTextFieldDidChanged),
                                               name: UITextField.textDidChangeNotification, object: citySearchTextField)

        getFullCityList()
        prepareSound()
        repairLikes()

        if likedLocations.count > 0 {
            if likedLocations.last == -1 {
                getCurrentLocationHourlyForecast()
            } else {
                cityTableViewDelegateHelper.partCityList = fullCityList.filter {
                    ($0.id == likedLocations.last)
                }
                citySearchTextField.text = "\(cityTableViewDelegateHelper.partCityList[0].name)" +
                                        "\(cityTableViewDelegateHelper.partCityList[0].country)"
                cityTableViewDelegateHelper.selectedGeoCoord = (cityTableViewDelegateHelper.partCityList[0].coord.lat,
                                                          cityTableViewDelegateHelper.partCityList[0].coord.lon)
                cityTableViewDelegateHelper.selectedCity = (cityTableViewDelegateHelper.partCityList[0].id,
                                                      cityTableViewDelegateHelper.partCityList[0].name,
                                                      cityTableViewDelegateHelper.partCityList[0].country)
                showCityForecast()
            }
            likeButton.isSelected = true
        }
    }

    func repairLikes() {
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        likedLocations = userDefaults.value(forKey: "list_of_city_likes") as? [Int] ?? []
    }

    func prepareSound() {
        if let backgroundAudioFileURL = Bundle.main.url(
            forResource: "Background sound",
            withExtension: "mp3"
        ) {
            do {
                let player = try AVAudioPlayer(contentsOf: backgroundAudioFileURL)
                player.prepareToPlay()
                player.delegate = self
                player.volume = 0.4
                backgroundPlayer = player
            } catch {
                print(error.localizedDescription)
            }
        }
        if let soundEffectAudioFileURL = Bundle.main.url(
            forResource: "Effect sound",
            withExtension: "mp3"
        ) {
            do {
                let player = try AVAudioPlayer(contentsOf: soundEffectAudioFileURL)
                player.prepareToPlay()
                player.delegate = self
                player.volume = 0.8
                soundEffectPlayer = player
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func getFullCityList() {
        if let path = Bundle.main.path(forResource: "city.list.min", ofType: "json"),
           let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
            if let decodedData = try? JSONDecoder().decode([CityList].self, from: data) {
                fullCityList = decodedData
            } else {print("bad json")}
        }
    }

    @objc func citySearchTextFieldDidChanged() {
        if citySearchTextField.text == "" {
            cityListTableView.alpha = 0
            hourlyForecastTableView.alpha = 1
        } else {
            if cityListTableView.alpha == 0 {
                cityListTableView.alpha = 1
                hourlyForecastTableView.alpha = 0
            }
            if let partCityName = citySearchTextField.text {
                searchListOfCitiesByPart(partCityName: partCityName)
                if cityListTableView.indexPathForSelectedRow?.row == 0
                    && cityTableViewDelegateHelper.partCityList.count > 0 {
                    cityTableViewDelegateHelper.selectedGeoCoord = (
                        cityTableViewDelegateHelper.partCityList[0].coord.lat,
                        cityTableViewDelegateHelper.partCityList[0].coord.lon
                    )
                    cityTableViewDelegateHelper.selectedCity = (
                        cityTableViewDelegateHelper.partCityList[0].id,
                        cityTableViewDelegateHelper.partCityList[0].name,
                        cityTableViewDelegateHelper.partCityList[0].country
                    )
                } else {
                    if cityTableViewDelegateHelper.partCityList.count == 0 {
                        cityTableViewDelegateHelper.selectedGeoCoord = (0.0, 0.0)
                        cityTableViewDelegateHelper.selectedCity = (0, "", "")
                    }
                }
            }
        }
    }

    func searchListOfCitiesByPart(partCityName: String) {
        cityTableViewDelegateHelper.partCityList = fullCityList.filter {
            ($0.name.uppercased().hasPrefix(partCityName.uppercased()))
        }
        cityListTableView.reloadData()
    }

    func getHourlyForecastbyCoordinates() {
        let lat = cityTableViewDelegateHelper.selectedGeoCoord.0
        let lon = cityTableViewDelegateHelper.selectedGeoCoord.1
        guard let url = URL(
            string: "https://api.openweathermap.org/data/2.5/onecall?lat=\(lat)&lon=\(lon)&exclude=daily&appid=0eb04ad449f01dd1766e48d84b0d27aa&units=\(units)&lang=\(lang)"
        ) else {
            print("incorrect URL")
            return
        }
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) {data, _, error in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            guard let data = data else {
                print("incorrect data")
                return
            }
            do {
                let post = try JSONDecoder().decode(HourlyForecast.self, from: data)
                self.forecastTableViewDelegateHelper.hourlyWeather = post
                DispatchQueue.main.async {
                    self.hourlyForecastTableView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }

    func showCityForecast() {
        cityListTableView.alpha = 0
        hourlyForecastTableView.alpha = 1
        getHourlyForecastbyCoordinates()
        citySearchTextField?.text = cityTableViewDelegateHelper.selectedCity.1 +
            " " + cityTableViewDelegateHelper.selectedCity.2
        if likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
            likeButton.isSelected = true
        } else {
            likeButton.isSelected = false
        }
    }

    func getCurrentLocationHourlyForecast() {
        cityListTableView.alpha = 0
        hourlyForecastTableView.alpha = 1
        cityTableViewDelegateHelper.selectedGeoCoord = savedCurrentLocation
        cityTableViewDelegateHelper.selectedCity = (-1, "Current".localized, "location".localized)
        citySearchTextField.text = cityTableViewDelegateHelper.selectedCity.1 +
            " " + cityTableViewDelegateHelper.selectedCity.2
        citySearchTextField.endEditing(true)
        getHourlyForecastbyCoordinates()
        if likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
            likeButton.isSelected = true
        } else {
            likeButton.isSelected = false
        }
    }

    @IBAction func soundButtonPressed(_ sender: Any) {
        switch isSoundEnable {
        case true:
            isSoundEnable = false
            soundButton.setImage(UIImage(systemName: "play.slash"), for: .normal)
            backgroundPlayer?.stop()
            soundEffectPlayer?.stop()
        case false:
            isSoundEnable = true
            soundButton.setImage(UIImage(systemName: "play"), for: .normal)
            backgroundPlayer?.play()
        }
    }

    @IBAction func likeButtonPressed(_ sender: Any) {
        if isSoundEnable {
            soundEffectPlayer?.play()
        }
        if likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
            if let index = likedLocations.firstIndex(of: cityTableViewDelegateHelper.selectedCity.0) {
                likedLocations.remove(at: index)
            }
        } else {
            likedLocations.append(cityTableViewDelegateHelper.selectedCity.0)
        }
        userDefaults.setValue(likedLocations, forKey: "list_of_city_likes")
        likeButton.isSelected = !likeButton.isSelected
    }

    @IBAction func currentLocationButtonPressed(_ sender: Any) {
        getCurrentLocationHourlyForecast()
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        savedCurrentLocation = (locations[0].coordinate.latitude, locations[0].coordinate.longitude)
        getCurrentLocationHourlyForecast()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch geoManager.authorizationStatus {
        case .denied, .notDetermined, .restricted:
            return
        default:
            geoManager.startUpdatingLocation()
            currentLocationButton.setBackgroundImage(UIImage(systemName: "location.fill.viewfinder"), for: .normal)
        }
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
}

extension ViewController: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isSoundEnable {
            backgroundPlayer?.play()
        } else {
            backgroundPlayer = nil
        }
    }
}
