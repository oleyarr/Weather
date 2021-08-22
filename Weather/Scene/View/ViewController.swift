//  ViewController.swift
//
//  Weather
//  Createdby Володя on 11.07.2021.
//

import UIKit
import CoreLocation

class ViewController: UIViewController {

    @IBOutlet weak var citySearchTextField: UITextField!
    @IBOutlet weak var cityListTableView: UITableView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var hourlyForecastTableView: UITableView!
    @IBOutlet weak var listOfLikedCitiesTableView: UITableView!
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var listOfLikedCitiesButton: UIButton!

    private var savedCurrentLocation = (0.0, 0.0)
    var fullCityList: [CityList] = []
    lazy var cityTableViewDelegateHelper = CityTableViewDelegateHelper(viewController: self)
    lazy var forecastTableViewDelegateHelper = ForecastTableViewDelegateHelper(viewController: self)
    lazy var listOfLikedCitiesTableViewDelegateHelper = ListOfLikedCitiesTableViewDelegateHelper(viewController: self)

    let geoManager = CLLocationManager()
    var likedLocations: [Int] = []
    var likedCityList: [CityList] = []

    private var lang = "RU"
    private var units = "Metric"
    private let userDefaults = UserDefaults.standard

    var viewModel: ViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ViewModelImplementation(viewController: self)
        viewModel?.didSoundButtonPressed = { isSoundEnable in
            switch isSoundEnable {
            case false:
                self.soundButton.setImage(UIImage(systemName: "play.slash"), for: .normal)
            case true:
                self.soundButton.setImage(UIImage(systemName: "play"), for: .normal)
            }
        }

        hourlyForecastTableView.dataSource = forecastTableViewDelegateHelper
        hourlyForecastTableView.delegate = forecastTableViewDelegateHelper
        hourlyForecastTableView.alpha = 1
        cityListTableView.dataSource = cityTableViewDelegateHelper
        cityListTableView.delegate = cityTableViewDelegateHelper
        cityListTableView.alpha = 0

        citySearchTextField.placeholder = "city search".localized
        citySearchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 0))
        citySearchTextField.leftViewMode = .always

        listOfLikedCitiesTableView.alpha = 0
        listOfLikedCitiesTableView.backgroundColor = .lightGray
        listOfLikedCitiesButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        listOfLikedCitiesButton.setImage(UIImage(systemName: "list.bullet.rectangle"), for: .selected)

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
        viewModel?.viewDidLoad()
        rememberLikes()

        switch rememberLastLocation() {
        case let(cityId) where cityId > 0:
            let city = fullCityList.filter({
                $0.id == cityId
            })
            citySearchTextField.text = "\(city[0].name) " + "\(city[0].country)"
            cityTableViewDelegateHelper.selectedGeoCoord = (city[0].coord.lat, city[0].coord.lon)
            cityTableViewDelegateHelper.selectedCity = (city[0].id,
                                                        city[0].name,
                                                        city[0].country)
            showCityForecast()
        case -1:
            getCurrentLocationHourlyForecast()
        default:
            return
        }
    }

    func rememberLikes() {
        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
        likedLocations = userDefaults.value(forKey: "list_of_city_likes") as? [Int] ?? []
        likedCityList = fullCityList.filter({
            likedLocations.contains($0.id)
        })
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
        listOfLikedCitiesTableView.alpha = 0
        listOfLikedCitiesButton.isSelected = false
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
                let decode = try JSONDecoder().decode(HourlyForecast.self, from: data)
                self.forecastTableViewDelegateHelper.hourlyWeather = decode
                DispatchQueue.main.async {
                    self.hourlyForecastTableView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        task.resume()
    }

    func saveLastLocation() {
        let lastLocation = String(cityTableViewDelegateHelper.selectedCity.0)
        userDefaults.setValue(lastLocation, forKey: "last_location")
    }

    func rememberLastLocation() -> (Int) {
        if let lastLocationAny = userDefaults.value(forKey: "last_location") {
            let lastLocationString = lastLocationAny as? String ?? "0"
            let lastLocationInt: Int = Int(lastLocationString) ?? 0
            return lastLocationInt
        }
        return 0
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
        saveLastLocation()
    }

    func getCurrentLocationHourlyForecast() {
        geoManager.delegate = self
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
        saveLastLocation()
    }

    func saveLike() {
        if likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
            if let index = likedLocations.firstIndex(of: cityTableViewDelegateHelper.selectedCity.0) {
                likedLocations.remove(at: index)
            }
        } else {
            likedLocations.append(cityTableViewDelegateHelper.selectedCity.0)
        }
        userDefaults.setValue(likedLocations, forKey: "list_of_city_likes")
    }

    @IBAction func soundButtonPressed(_ sender: Any) {
        if let isSoundEnabled = viewModel?.isSoundEnabled {
            viewModel?.isSoundEnabled = !isSoundEnabled
        }
    }

    @IBAction func listOfLikedCitiesButtonPressed(_ sender: Any) {
        listOfLikedCitiesButton.isSelected = !listOfLikedCitiesButton.isSelected
        if listOfLikedCitiesButton.isSelected {
            listOfLikedCitiesTableView.alpha = 1
            hourlyForecastTableView.alpha = 0.5
            listOfLikedCitiesTableView.dataSource = listOfLikedCitiesTableViewDelegateHelper
            listOfLikedCitiesTableView.delegate = listOfLikedCitiesTableViewDelegateHelper
            listOfLikedCitiesTableView.reloadData()
        } else {
            listOfLikedCitiesTableView.alpha = 0
            hourlyForecastTableView.alpha = 1
        }
    }

    @IBAction func likeButtonPressed(_ sender: Any) {
        if (viewModel?.isSoundOn) == true {
            viewModel?.soundEffectPlayer?.play()
        }
        saveLike()
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
