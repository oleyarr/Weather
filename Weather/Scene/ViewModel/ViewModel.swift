//
//  ViewModel.swift
//  Weather
//
//  Created by Володя on 18.08.2021.
//

import Foundation
import AVKit

protocol ViewModel {
    var didSoundButtonPressed: ((Bool) -> ())? { get set }
    var isSoundOn: Bool { get set }
    var isSoundEnabled: Bool { get set }
    var backgroundPlayer: AVAudioPlayer? { get set }
    var soundEffectPlayer: AVAudioPlayer? { get set }
    func prepareSound()
    func viewDidLoad()
    func getFullCityList()
    var fullCityList: [CityList] { get set }
    var likedCityList: [CityList] { get set }
    var likedLocations: [Int] { get set }
    func fillLikedCityList()
    var userDefaults: UserDefaults { get set }
    func rememberLastLocation()
    func getHourlyForecastbyCoordinates()
    var lang: String { get set }
    var units: String { get set }
    func deleteLike(cityId: Int)
    func setLike(cityId: Int)
    func resortLikedCities()
}

class ViewModelImplementation: NSObject, ViewModel {
    var viewController: ViewController
    init(viewController: ViewController) {
        self.viewController = viewController
    }
    lazy var cityTableViewDelegateHelper = viewController.cityTableViewDelegateHelper
    lazy var forecastTableViewDelegateHelper = viewController.forecastTableViewDelegateHelper
    lazy var listOfLikedCitiesTableViewDelegateHelper = viewController.listOfLikedCitiesTableViewDelegateHelper

    var didSoundButtonPressed: ((Bool) -> ())?
    var backgroundPlayer: AVAudioPlayer?
    var soundEffectPlayer: AVAudioPlayer?

    var isSoundOn: Bool = false
    var isSoundEnabled: Bool = false {
        didSet {
            isSoundOn = isSoundEnabled
            self.didSoundButtonPressed?(isSoundEnabled)
            // бизнес-логика
            if isSoundEnabled {
                backgroundPlayer?.play()
            } else {
                backgroundPlayer?.stop()
            }
        }
    }
    var fullCityList: [CityList] = []
    var likedCityList: [CityList] = []
    var likedLocations: [Int] = []
    var userDefaults = UserDefaults.standard
    var lang = "RU"
    var units = "Metric"

    func viewDidLoad() {
        prepareSound()
        getFullCityList()
        fillLikedCityList()
        rememberLastLocation()
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
                player.volume = 0.5
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

    func fillLikedCityList() {
        likedLocations = userDefaults.value(forKey: "list_of_city_likes") as? [Int] ?? []
        likedCityList = fullCityList.filter({
            likedLocations.contains($0.id)
        }).sorted(by: {$0.name < $1.name})
    }

//    func setOrRemoveLike() {
//        if likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
//            if let index = likedLocations.firstIndex(of: cityTableViewDelegateHelper.selectedCity.0) {
//                likedLocations.remove(at: index)
//            }
//        } else {
//            likedLocations.append(cityTableViewDelegateHelper.selectedCity.0)
//        }
//        userDefaults.setValue(likedLocations, forKey: "list_of_city_likes")
//        resortLikedCities()
//    }

    func deleteLike(cityId: Int) {
        if let likedLocationIndex = likedLocations.firstIndex(of: cityId) {
            likedLocations.remove(at: likedLocationIndex)
            if let likedCityListIndex = likedCityList.firstIndex(where: { cityList in
                                                                    cityList.id == cityId }) {
                likedCityList.remove(at: likedCityListIndex)
            }
            userDefaults.setValue(likedLocations, forKey: "list_of_city_likes")
        }
        resortLikedCities()
        viewController.changeLikeVisualState()
    }

    func setLike(cityId: Int) {
        likedLocations.append(cityId)
        resortLikedCities()
        viewController.changeLikeVisualState()
    }

    func resortLikedCities() {
        likedCityList = fullCityList.filter({
            likedLocations.contains($0.id)
        }).sorted(by: {$0.name < $1.name})
    }

    func rememberLastLocation() {
        if let lastLocationAny = userDefaults.value(forKey: "last_location") {
            let lastLocationString = lastLocationAny as? String ?? "0"
            let lastLocationInt: Int = Int(lastLocationString) ?? 0
            switch lastLocationInt {
            case let(cityId) where cityId > 0:
                let city = fullCityList.filter({
                    $0.id == cityId
                })
                viewController.citySearchTextField.text = "\(city[0].name) " + "\(city[0].country)"
                viewController.cityTableViewDelegateHelper.selectedGeoCoord = (city[0].coord.lat,
                                                                                city[0].coord.lon)
                cityTableViewDelegateHelper.selectedCity = (city[0].id,
                                                            city[0].name,
                                                            city[0].country)
                viewController.showCityForecast()
            case -1:
                viewController.getCurrentLocationHourlyForecast()
            default:
                return
            }
        }
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
                let decode = try JSONDecoder().decode(HourlyForecast.self, from: data)
                self.forecastTableViewDelegateHelper.hourlyWeather = decode
                DispatchQueue.main.async {
                    self.viewController.hourlyForecastTableView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }
}

extension ViewModelImplementation: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if isSoundOn {
            backgroundPlayer?.play()
        } else {
            backgroundPlayer = nil
        }
    }
}
