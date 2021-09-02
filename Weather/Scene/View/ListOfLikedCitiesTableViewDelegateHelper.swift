import UIKit

class ListOfLikedCitiesTableViewDelegateHelper: NSObject, UITableViewDataSource, UITableViewDelegate {

        var viewController: ViewController
        init(viewController: ViewController) {
            self.viewController = viewController
            super.init()
        }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewController.viewModel?.likedCityListCount() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        viewController.setLikedCitiesTableViewHeight(contentSizeHeight: tableView.contentSize.height)
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
        viewController.selectCityInLikedCityList()
        viewController.viewModel?.showLikedCityRow(indexPathRow: indexPath.row)
        viewController.showCityForecast()
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
                viewController.viewModel?.deleteLike(cityId: viewModel.likedCityList[indexPath.row].id)
            }
            tableView.endUpdates()
        }
        viewController.setLikedCitiesTableViewHeight(contentSizeHeight: tableView.contentSize.height)
    }
}
