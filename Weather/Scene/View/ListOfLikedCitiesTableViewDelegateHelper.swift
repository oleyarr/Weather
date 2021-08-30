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
        return rowsCount()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CustomCell", for: indexPath)
        cell.textLabel?.textColor = .systemBlue
        cell.backgroundColor = .lightGray
        if  let viewModel = viewController.viewModel {
        cell.textLabel?.text =
            "\(String(describing: viewModel.likedCityList[indexPath.row].name)) "
            +
            "\(String(describing: viewModel.likedCityList[indexPath.row].country))"
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        viewController.listOfLikedCitiesTableView.alpha = 0
        viewController.listOfLikedCitiesButton.layer.shadowOpacity = 0
        viewController.listOfLikedCitiesButton.isSelected = !viewController.listOfLikedCitiesButton.isSelected
        if let viewModel = viewController.viewModel {
            viewController.cityTableViewDelegateHelper.selectedGeoCoord = (
                viewModel.likedCityList[indexPath.row].coord.lat,
                viewModel.likedCityList[indexPath.row].coord.lon
            )
            viewController.cityTableViewDelegateHelper.selectedCity = (
                viewModel.likedCityList[indexPath.row].id,
                viewModel.likedCityList[indexPath.row].name,
                viewModel.likedCityList[indexPath.row].country
            )
            viewController.showCityForecast()
        }
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let rowHeight = 44
        return CGFloat(rowHeight)
    }

    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            if let viewModel = viewController.viewModel {
                viewModel.deleteLike(cityId: viewModel.likedCityList[indexPath.row].id)
            }
            tableView.endUpdates()
        }
    }

    func rowsCount() -> Int {
        return viewController.viewModel?.likedCityList.count ?? 0
    }
}
