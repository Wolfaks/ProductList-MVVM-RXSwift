
import UIKit
import RxCocoa
import RxSwift

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

    let DBag = DisposeBag()

    static func storyboardInstance() -> DetailViewController? {
        // Для перехода на эту страницу
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "Detail") as? DetailViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingUI()
        setupBindings()
    }
    
    private func settingUI() {

        // Задаем заголовок страницы
        if let productTitle = productTitle {
            title = productTitle
        }

        if let id = productID {

            // viewModel
            viewModel = DetailViewModel(productID: id, amount: productSelectedAmount)

            // tableView
            tableView.rowHeight = 32.0

        }
        
    }

    private func setupBindings() {
        bindViewToViewModel()
        bindViewModelToView()
    }

    private func bindViewToViewModel() {
    }

    private func bindViewModelToView() {

        // Получение данных из viewModel
        viewModel.dataReceived.subscribe(onNext: { [weak self] update in

            // Скрываем анимацию загрузки
            self?.loadIndicator.stopAnimating()

            // Задаем обновленный заголовок страницы
            self?.title = self?.viewModel.title

            // Выводим информацию
            self?.titleLabel.text = self?.viewModel.title
            self?.producerLabel.text = self?.viewModel.producer
            self?.priceLabel.text = self?.viewModel.price
            self?.image.image = self?.viewModel.image

            // Описание
            self?.changeDescription(text: self?.viewModel.shortDescription ?? "")

            // Вывод корзины и кол-ва добавленых в корзину
            self?.setCartButtons()

            // Отображаем данные
            self?.infoStackView.isHidden = false

        }, onError: { [weak self] error in
            print(error)
        }).disposed(by: DBag)

        // Вывод данных
        viewModel.categoryList.bind(to: tableView.rx.items(cellIdentifier: "categoryCell", cellType: CategoryListTableCell.self)) {
            (row, item, cell) in

            let cellViewModel = self.viewModel.cellViewModel(index: row)
            cell.viewModel = cellViewModel

        }.disposed(by: DBag)
        
        // Клик на добавление в карзину
        let tapCartBtnGesture = UITapGestureRecognizer()
        cartBtnDetailView.addGestureRecognizer(tapCartBtnGesture)
        tapCartBtnGesture.rx
                .event
                .subscribe { [weak self] recognizer in
                    
                    // Добавляем товар в карзину
                    guard let productIndex = self?.productIndex, self?.viewModel != nil else { return }

                    let addCartCount = 1
                    
                    // Обновляем кнопку в отображении
                    self?.viewModel.changeCartCount(index: productIndex, count: addCartCount)
                    self?.setCartButtons()
                    
                }.disposed(by: DBag)
        
        // Изменение количества в корзине
        cartCountView.countSubject.subscribe(onNext: { [weak self] value in
            
            // Изменяем значение количества в моделе
            guard let productIndex = self?.productIndex, self?.viewModel != nil else { return }
            
            // Обновляем кнопку в отображении
            self?.viewModel.changeCartCount(index: productIndex, count: value)
            self?.setCartButtons()
            
        }, onError: { [weak self] error in
            print(error)
        }).disposed(by: DBag)

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
            
        } else {
            // Выводим кнопку добавления в карзину
            cartBtnDetailView.isHidden = false
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
