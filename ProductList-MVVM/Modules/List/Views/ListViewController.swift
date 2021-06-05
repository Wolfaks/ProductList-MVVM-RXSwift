
import UIKit

class ListViewController: UIViewController {

    @IBOutlet weak var searchForm: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!

    // viewModel
    var viewModel: ListViewModelProtocol?

    // Поиск
    var searchText = ""
    var searchTimer = Timer()

    // Страницы
    var page = 1
    var haveNextPage = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingUI()
    }
    
    private func settingUI() {

        // viewModel
        viewModel = ListViewModel()

        // searchForm
        searchForm.delegate = self
        searchForm.addTarget(self, action: #selector(changeSearchText), for: .editingChanged) // добавляем отслеживание изменения текста
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 160.0

        // Наблюдатель изменения товаров в корзине
        NotificationCenter.default.addObserver(self, selector: #selector(updateCartCount), name: Notification.Name(rawValue: "notificationUpdateCartCount"), object: nil)

        // Наблюдатель перехода в детальную информацию
        NotificationCenter.default.addObserver(self, selector: #selector(showDetail), name: Notification.Name(rawValue: "notificationRedirectToDetail"), object: nil)
        
        // Запрос данных
        loadProducts()
        
    }

    @objc func updateCartCount(notification: Notification) {

        // Изменяем кол-во товара в корзине
        guard let userInfo = notification.userInfo, let index = userInfo["index"] as? Int, let newCount = userInfo["count"] as? Int, let viewModel = viewModel, !viewModel.productList.isEmpty && viewModel.productList.indices.contains(index) else { return }

        // Записываем новое значение
        viewModel.updateCartCount(index: index, value: newCount)

        // Обновляем tableView
        tableView.reloadData()

    }

    @objc func showDetail(notification: Notification) {

        // Переход в детальную информацию
        guard let userInfo = notification.userInfo, let index = userInfo["index"] as? Int, let viewModel = viewModel, !viewModel.productList.isEmpty && viewModel.productList.indices.contains(index) else { return }

        // Выполняем переход в детальную информацию
        if let detailViewController = DetailViewController.storyboardInstance() {
            detailViewController.productIndex = index
            detailViewController.productID = viewModel.productList[index].id
            detailViewController.productTitle = viewModel.productList[index].title
            detailViewController.productSelectedAmount = viewModel.productList[index].selectedAmount
            navigationController?.pushViewController(detailViewController, animated: true)
        }

    }
    
    @IBAction func removeSearch(_ sender: Any) {
        
        // Очищаем форму поиска
        searchForm.text = ""
        
        // Скрываем клавиатуру
        hideKeyboard()
        
        // Вызываем метод поиска
        changeSearchText(textField: searchForm)
        
    }
    
    func hideKeyboard() {
        view.endEditing(true);
    }
    
    @objc func delayedSearch() {

        // Выполняем поиск

        // Задаем первую страницу
        page = 1

        // Запрос данных
        loadProducts()

    }
    
    @objc func changeSearchText(textField: UITextField) {

        // Проверяем измененный в форме текст
        guard let newSearchText = textField.text else { return }
        
        // Выполняем поиск когда форма была изменена
        if newSearchText.hash == searchText.hash {
            return
        }

        // Получаем искомую строку
        searchText = newSearchText

        // Очищаем старые данные и обновляем таблицу
        removeOldProducts()

        // Отменяем предыдущий таймер поиска
        searchTimer.invalidate()

        // Таймер задержки поиска (по ТЗ)
        searchTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(delayedSearch), userInfo: nil, repeats: false)
        
    }
    
    func removeOldProducts() {

        guard let viewModel = viewModel else { return }
        
        // Очищаем старые данные и обновляем таблицу
        viewModel.removeAllProducts()
        tableView.reloadData()
        
        // Отображаем анимацию загрузки
        loadIndicator.startAnimating()
        
    }
    
    func loadProducts() {
        
        // Отправляем запрос загрузки товаров
        ProductNetworking.getProducts(page: page, searchText: searchText) { [weak self] (response) in
            
            // Скрываем анимацию загрузки
            if self?.page == 1 {
                self?.loadIndicator.stopAnimating()
            }

            // Обрабатываем полученные товары
            var products = response.products

            // Так как API не позвращает отдельный ключ, который говорит о том, что есть следующая страница, определяем это вручную
            if !products.isEmpty && products.count == ProductNetworking.maxProductsOnPage {

                // Задаем наличие следующей страницы
                self?.haveNextPage = true

                // Удаляем последний элемент, который используется только для проверки на наличие следующей страницы
                products.remove(at: products.count - 1)

            }

            // Устанавливаем загруженные товары и обновляем таблицу
            // append contentsOf так как у нас метод грузит как первую страницу, так и последующие
            self?.viewModel?.appendProducts(products: products)
            self?.tableView.reloadData()
            
        }
        
    }
    
}

extension ListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.numberOfRows() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "productCell", for: indexPath) as? ProductListTableCell, let viewModel = viewModel else { return UITableViewCell() }

        let cellViewModel = viewModel.cellViewModel(forIndexPath: indexPath)
        cell.productIndex = indexPath.row
        cell.viewModel = cellViewModel

        return cell

    }

}

extension ListViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        // Проверяем что оторазили последний элемент и если есть, отображаем следующую страницу
        if let viewModel = viewModel, !viewModel.productList.isEmpty && indexPath.row == (viewModel.productList.count - 1) && haveNextPage {

            // Задаем новую страницу
            haveNextPage = false
            page += 1

            // Запрос данных
            loadProducts()

        }
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
