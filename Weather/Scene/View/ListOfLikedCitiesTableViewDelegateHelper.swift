
// как выводить только нужное число записей - подгонять вьюху по размеру?
// как прыгать на первую запись при обновлении таблицы с прогнозом, независимо от того куда таблицу отмотали

import UIKit

class ListOfLikedCitiesTableViewDelegateHelper: NSObject, UITableViewDataSource, UITableViewDelegate {

    var viewController: ViewController

    init(viewController: ViewController) {
        self.viewController = viewController
        super.init()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewController.likedCityList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.backgroundColor = .lightGray
        cell.textLabel?.text =
            "\(viewController.likedCityList[indexPath.row].name) "
            +
            "\(viewController.likedCityList[indexPath.row].country)"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewController.listOfLikedCitiesTableView.alpha = 0
        viewController.listOfLikedCitiesButton.isSelected = !viewController.listOfLikedCitiesButton.isSelected
        viewController.cityTableViewDelegateHelper.selectedGeoCoord = (
            viewController.likedCityList[indexPath.row].coord.lat,
            viewController.likedCityList[indexPath.row].coord.lon
        )
        viewController.cityTableViewDelegateHelper.selectedCity = (
            viewController.likedCityList[indexPath.row].id,
            viewController.likedCityList[indexPath.row].name,
            viewController.likedCityList[indexPath.row].country
        )
        viewController.showCityForecast()
    }
}
