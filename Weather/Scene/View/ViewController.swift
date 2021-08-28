//  ViewController.swift
//
//  Weather
//  Createdby Володя on 11.07.2021.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var citySearchTextField: UITextField!
    @IBOutlet weak var cityListTableView: UITableView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var hourlyForecastTableView: UITableView!
    @IBOutlet weak var listOfLikedCitiesTableView: UITableView!
    @IBOutlet weak var soundButton: UIButton!
    @IBOutlet weak var likeButton: UIButton!
    @IBOutlet weak var listOfLikedCitiesButton: UIButton!

    var savedCurrentLocation = (0.0, 0.0)
    lazy var cityTableViewDelegateHelper = CityTableViewDelegateHelper(viewController: self)
    lazy var forecastTableViewDelegateHelper = ForecastTableViewDelegateHelper(viewController: self)
    lazy var listOfLikedCitiesTableViewDelegateHelper = ListOfLikedCitiesTableViewDelegateHelper(viewController: self)
    lazy var geoManager = GeoManager()

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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(citySearchTextFieldDidChanged),
                                               name: UITextField.textDidChangeNotification, object: citySearchTextField)
        initTablesAndButtons()
        viewModel?.viewDidLoad()
    }

    func initTablesAndButtons() {
        hourlyForecastTableView.dataSource = forecastTableViewDelegateHelper
        hourlyForecastTableView.delegate = forecastTableViewDelegateHelper
        hourlyForecastTableView.alpha = 1
        cityListTableView.dataSource = cityTableViewDelegateHelper
        cityListTableView.delegate = cityTableViewDelegateHelper
        cityListTableView.alpha = 0

        listOfLikedCitiesTableView.dataSource = listOfLikedCitiesTableViewDelegateHelper
        listOfLikedCitiesTableView.delegate = listOfLikedCitiesTableViewDelegateHelper
        listOfLikedCitiesTableView.clipsToBounds = false
        listOfLikedCitiesTableView.layer.shadowOpacity = 0.5
        listOfLikedCitiesTableView.layer.shadowColor = UIColor.black.cgColor
        listOfLikedCitiesTableView.layer.shadowOffset = CGSize(width: 3, height: 3)
        listOfLikedCitiesTableView.alpha = 0

        citySearchTextField.placeholder = "city search".localized
        citySearchTextField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 35, height: 0))
        citySearchTextField.leftViewMode = .always

        listOfLikedCitiesButton.setImage(UIImage(systemName: "list.bullet"), for: .normal)
        listOfLikedCitiesButton.setImage(UIImage(systemName: "list.bullet.rectangle"), for: .selected)
        listOfLikedCitiesButton.clipsToBounds = false
        listOfLikedCitiesTableView.layer.shadowOpacity = 0
        listOfLikedCitiesButton.layer.shadowColor = UIColor.black.cgColor
        listOfLikedCitiesButton.layer.shadowOffset = CGSize(width: 3, height: 3)

        likeButton.setImage(UIImage(systemName: "heart"), for: .normal)
        likeButton.setImage(UIImage(systemName: "heart.fill"), for: .selected)
    }

    @objc func citySearchTextFieldDidChanged() {
        listOfLikedCitiesTableView.alpha = 0
        listOfLikedCitiesButton.isSelected = false
        listOfLikedCitiesButton.layer.shadowOpacity = 0
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
        cityTableViewDelegateHelper.partCityList = viewModel!.fullCityList.filter {
            ($0.name.uppercased().hasPrefix(partCityName.uppercased()))
        }
        cityListTableView.reloadData()
    }

    func saveLastLocation() {
        let lastLocation = String(cityTableViewDelegateHelper.selectedCity.0)
        userDefaults.setValue(lastLocation, forKey: "last_location")
    }

    func showCityForecast() {
        cityListTableView.alpha = 0
        hourlyForecastTableView.alpha = 1
        viewModel?.getHourlyForecastbyCoordinates()
        guard let viewModel = viewModel else {return}
        if viewModel.likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
            likeButton.isSelected = true
        } else {
            likeButton.isSelected = false
        }
        citySearchTextField?.text = cityTableViewDelegateHelper.selectedCity.1 +
            " " + cityTableViewDelegateHelper.selectedCity.2
        saveLastLocation()
    }

    func getCurrentLocationHourlyForecast() {
        geoManager = .init()
        cityListTableView.alpha = 0
        hourlyForecastTableView.alpha = 1
        citySearchTextField.endEditing(true)
        cityTableViewDelegateHelper.selectedGeoCoord = savedCurrentLocation
        cityTableViewDelegateHelper.selectedCity = (-1, "Current".localized, "location".localized)
        citySearchTextField.text = cityTableViewDelegateHelper.selectedCity.1 +
            " " + cityTableViewDelegateHelper.selectedCity.2
        viewModel?.getHourlyForecastbyCoordinates()
        guard let viewModel = viewModel else {return}
        if viewModel.likedLocations.contains(cityTableViewDelegateHelper.selectedCity.0) {
            likeButton.isSelected = true
        } else {
            likeButton.isSelected = false
        }
        saveLastLocation()
    }

    @IBAction func soundButtonPressed(_ sender: Any) {
        if let isSoundEnabled = viewModel?.isSoundEnabled {
            viewModel?.isSoundEnabled = !isSoundEnabled
        }
    }

    @IBAction func listOfLikedCitiesButtonPressed(_ sender: Any) {
        listOfLikedCitiesButton.isSelected = !listOfLikedCitiesButton.isSelected
        listOfLikedCitiesTableView.alpha = 0
        if listOfLikedCitiesButton.isSelected {
            hourlyForecastTableView.alpha = 0.5
            listOfLikedCitiesTableView.alpha = 1
            listOfLikedCitiesTableView.reloadData()
            listOfLikedCitiesButton.layer.shadowOpacity = 0.5
        } else {
            listOfLikedCitiesTableView.alpha = 0
            hourlyForecastTableView.alpha = 1
            listOfLikedCitiesButton.layer.shadowOpacity = 0
        }
    }

    @IBAction func likeButtonPressed(_ sender: Any) {
        viewModel?.setLike()
        likeButton.isSelected = !likeButton.isSelected
        if (viewModel?.isSoundOn) == true {
            viewModel?.soundEffectPlayer?.play()
        }
    }

    @IBAction func currentLocationButtonPressed(_ sender: Any) {
        listOfLikedCitiesButton.layer.shadowOpacity = 0
        listOfLikedCitiesTableView.alpha = 0
        getCurrentLocationHourlyForecast()
    }
}
