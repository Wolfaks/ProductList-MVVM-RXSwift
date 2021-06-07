
import UIKit
import RxCocoa
import RxSwift

class ListViewController: UIViewController {

    @IBOutlet weak var searchForm: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!

    // viewModel
    var viewModel: ListViewModelProtocol!
    let DBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingUI()
    }
    
    private func settingUI() {

        // Наблюдатель изменения товаров в корзине
        NotificationCenter.default.addObserver(self, selector: #selector(updateCartCount), name: Notification.Name(rawValue: "notificationUpdateCartCount"), object: nil)

        // Наблюдатель перехода в детальную информацию
        NotificationCenter.default.addObserver(self, selector: #selector(showDetail), name: Notification.Name(rawValue: "notificationRedirectToDetail"), object: nil)

        // viewModel
        viewModel = ListViewModel()
        viewModel.showLoadIndicator = { [weak self] in
            // Отображаем анимацию загрузки
            self?.loadIndicator.startAnimating()
        }
        viewModel.hideLoadIndicator = { [weak self] in
            // Скрываем анимацию загрузки
            self?.loadIndicator.stopAnimating()
        }

        // tableView
        settingTableView()

        // search
        settingSearch()
        
    }
    private func settingTableView() {

        // tableView
        tableView.rowHeight = 160.0

        // Вывод данных
        viewModel.productList.bind(to: tableView.rx.items(cellIdentifier: "productCell", cellType: ProductListTableCell.self)) {
            (row, item, cell) in

            let cellViewModel = self.viewModel.cellViewModel(product: item)
            cell.productIndex = row
            cell.viewModel = cellViewModel

        }.disposed(by: DBag)

        // Индекс отображаемых ячеек
        tableView.rx
                .willDisplayCell
                .asObservable()
                .subscribe { [weak self] ( _, indexPath) in

                    // Проверяем что оторазили последний элемент и если есть, отображаем следующую страницу
                    guard self?.viewModel != nil else { return }
                    self?.viewModel.visibleCell(Index: indexPath.row)

                }.disposed(by: DBag)

    }

    private func settingSearch() {

        // Кнопка done
        searchForm.delegate = self

        // Связываем TextField с поисков в ListViewModel
        searchForm.rx.text
                .orEmpty
                .throttle(.milliseconds(600), scheduler: MainScheduler.instance)
                .distinctUntilChanged()
                .do(onNext: nil)
                .bind(to: viewModel.searchText).disposed(by: DBag)

    }

    @objc func updateCartCount(notification: Notification) {

        // Изменяем кол-во товара в корзине
        guard let userInfo = notification.userInfo, let index = userInfo["index"] as? Int, let newCount = userInfo["count"] as? Int, let viewModel = viewModel, !viewModel.productListArr.isEmpty && viewModel.productListArr.indices.contains(index) else { return }

        // Записываем новое значение
        viewModel.updateCartCount(index: index, value: newCount)

    }

    @objc func showDetail(notification: Notification) {

        // Переход в детальную информацию
        guard let userInfo = notification.userInfo, let index = userInfo["index"] as? Int, let viewModel = viewModel, !viewModel.productListArr.isEmpty && viewModel.productListArr.indices.contains(index) else { return }

        // Выполняем переход в детальную информацию
        if let detailViewController = DetailViewController.storyboardInstance() {
            detailViewController.productIndex = index
            detailViewController.productID = viewModel.productListArr[index].id
            detailViewController.productTitle = viewModel.productListArr[index].title
            detailViewController.productSelectedAmount = viewModel.productListArr[index].selectedAmount
            navigationController?.pushViewController(detailViewController, animated: true)
        }

    }
    
    @IBAction func removeSearch(_ sender: Any) {

        // Скрываем клавиатуру
        hideKeyboard()
        
        // Очищаем форму поиска
        searchForm.text = ""
        
    }
    
    func hideKeyboard() {
        view.endEditing(true);
    }
    
}

extension ListViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == searchForm {
            // Скрываем клавиатуру при нажатии на клавишу Done / Готово
            hideKeyboard()
        }
        
        return true
        
    }
    
}
