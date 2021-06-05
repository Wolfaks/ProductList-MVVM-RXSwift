
import UIKit

class DetailViewController: UIViewController {
    
    var productIndex: Int?
    var productID: Int?
    var productTitle: String?
    var productSelectedAmount = 0
    
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!
    @IBOutlet weak var infoStackView: UIStackView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var producerLabel: UILabel!
    @IBOutlet weak var image: UIImageView!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var cartBtnDetailView: CartBtnDetail!
    @IBOutlet weak var cartCountView: CartCount!

    // viewModel
    var viewModel: DetailViewModelProtocol!

    static func storyboardInstance() -> DetailViewController? {
        // Для перехода на эту страницу
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "Detail") as? DetailViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingUI()
    }
    
    private func settingUI() {

        // Задаем заголовок страницы
        if let productTitle = productTitle {
            title = productTitle
        }
        
        // TableView
        tableView.delegate = self
        tableView.dataSource = self
        
        // Запрос данных
        // viewModel
        if let id = productID {
            viewModel = DetailViewModel(productID: id, amount: productSelectedAmount)
            viewModel.bindToController = { [weak self] in

                // Скрываем анимацию загрузки
                self?.loadIndicator.stopAnimating()

                // Задаем обновленный заголовок страницы
                self?.title = self?.viewModel.title

                // Выводим информацию
                self?.titleLabel.text = self?.viewModel.title
                self?.producerLabel.text = self?.viewModel.producer
                self?.priceLabel.text = self?.viewModel.price

                // Описание
                self?.changeDescription(text: self?.viewModel.shortDescription ?? "")

                // Загрузка изображения, если ссылка пуста, то выводится изображение по умолчанию
                self?.image.image = UIImage(named: "nophoto")
                if !(self?.viewModel.imageUrl.isEmpty ?? false) {

                    // Загрузка изображения
                    guard let imageURL = URL(string: (self?.viewModel.imageUrl)!) else {
                        return
                    }
                    ImageNetworking.networking.getImage(link: imageURL) { (img) in
                        DispatchQueue.main.async {
                            self?.image.image = img
                        }
                    }

                }

                // Вывод корзины и кол-ва добавленых в корзину
                self?.setCartButtons()

                // Оббновляем таблицу
                self?.tableView.reloadData()

                // Отображаем данные
                self?.infoStackView.isHidden = false

            }
        }
        
    }
    
    func setCartButtons() {

        guard let viewModel = viewModel else { return }

        // Вывод корзины и кол-ва добавленых в корзину
        if viewModel.selectedAmount > 0 {
            
            // Выводим переключатель кол-ва продукта в корзине
            cartBtnDetailView.isHidden = true
            cartCountView.isHidden = false
            
            // Задаем текущее значение счетчика
            cartCountView.count = viewModel.selectedAmount
            
            // Подписываемся на делегат
            cartCountView.delegate = self
            
        } else {
            // Выводим кнопку добавления в карзину
            cartBtnDetailView.isHidden = false
            cartBtnDetailView.delegate = self
            cartCountView.isHidden = true
        }
        
    }
    
    func changeDescription(text: String) {
        
        // Задаем описание
        if text.isEmpty {
            descriptionLabel.isHidden = true
            descriptionLabel.text = ""
        } else {
            descriptionLabel.isHidden = false
            descriptionLabel.text = text
        }
        
    }
    
}

extension DetailViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel?.numberOfRows() ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "categoryCell", for: indexPath) as? CategoryListTableCell, let viewModel = viewModel else { return UITableViewCell() }

        let cellViewModel = viewModel.cellViewModel(forIndexPath: indexPath)
        cell.viewModel = cellViewModel

        return cell

    }

}

extension DetailViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        32.0
    }

}

extension DetailViewController: CartCountDelegate {
    
    func changeCount(value: Int) {
        
        // Изменяем значение количества в структуре
        guard let productIndex = productIndex, viewModel != nil else { return }
        
        // Обновляем кнопку в отображении
        viewModel.selectedAmount = value
        setCartButtons()
        
        // Обновляем значение в корзине в списке через наблюдатель
        NotificationCenter.default.post(name: Notification.Name(rawValue: "notificationUpdateCartCount"), object: nil, userInfo: ["index": productIndex, "count": value])
        
    }
    
}

extension DetailViewController: CartBtnDetailDelegate {
    
    func addCart() {
        
        // Добавляем товар в карзину
        guard let productIndex = productIndex, viewModel != nil else { return }

        let addCartCount = 1
        
        // Обновляем кнопку в отображении
        viewModel.selectedAmount = addCartCount
        setCartButtons()

        // Обновляем значение в корзине в списке через наблюдатель
        NotificationCenter.default.post(name: Notification.Name(rawValue: "notificationUpdateCartCount"), object: nil, userInfo: ["index": productIndex, "count": addCartCount])
        
    }
    
}
