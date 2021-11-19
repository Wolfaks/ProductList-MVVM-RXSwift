
import UIKit
import RxCocoa
import RxSwift

protocol DetailViewControllerProtocol: class {
    var cardCountUpdateSubject: PublishSubject<CardCountUpdate> { get }
    func setProductData(productIndex: Int, productID: Int, productTitle: String, productSelectedAmount: Int)
}

class DetailViewController: UIViewController, DetailViewControllerProtocol {
    
    var productIndex: Int?
    var productID: Int?
    var productTitle: String?
    var productSelectedAmount = 0
    
    var cardCountUpdateSubject = PublishSubject<CardCountUpdate>()
    
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
    var viewModel: DetailViewModelProtocol?

    let DBag = DisposeBag()

    static func storyboardInstance() -> DetailViewController? {
        // Для перехода на эту страницу
        let storyboard = UIStoryboard(name: "Detail", bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: "Detail") as? DetailViewController
    }
    
    func setProductData(productIndex: Int, productID: Int, productTitle: String, productSelectedAmount: Int) {
        self.productIndex = productIndex
        self.productID = productID
        self.productTitle = productTitle
        self.productSelectedAmount = productSelectedAmount
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
            viewModel = DetailViewModel()
            viewModel?.input.selectedAmount = productSelectedAmount
            viewModel?.input.id.accept(id)
            
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
        viewModel?.output.loaded.subscribe(onNext: { [weak self] loaded in

            guard loaded, let product = self?.viewModel?.output.product else { return }
            
            // Скрываем анимацию загрузки
            self?.loadIndicator.stopAnimating()

            // Задаем обновленный заголовок страницы
            self?.title = product.title

            // Выводим информацию
            self?.titleLabel.text = product.title
            self?.producerLabel.text = product.producer
            self?.image.image = self?.viewModel?.output.image
            
            // Убираем лишние нули после запятой, если они есть и выводим цену
            self?.priceLabel.text = String(format: "%g", product.price) + " ₽"

            // Описание
            self?.changeDescription(text: product.shortDescription)

            // Вывод корзины и кол-ва добавленых в корзину
            self?.setCartButtons()

            // Отображаем данные
            self?.infoStackView.isHidden = false

        }, onError: { [weak self] error in
            print(error)
        }).disposed(by: DBag)
        
        // Обновление товара в корзине
        viewModel?.output.cardCountUpdateSubject.subscribe(onNext: { [weak self] cardCountUpdate in

            // Вывод корзины и кол-ва добавленых в корзину
            self?.updateCartCount(cardCountUpdate: cardCountUpdate)
            self?.setCartButtons()

        }, onError: { [weak self] error in
            print(error)
        }).disposed(by: DBag)

        // Вывод данных
        viewModel?.output.categoryList.bind(to: tableView.rx.items(cellIdentifier: "categoryCell", cellType: CategoryListTableCell.self)) {
            (row, item, cell) in

            let cellViewModel = self.viewModel?.cellViewModel(index: row)
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
                    let cardCountUpdate = CardCountUpdate(index: productIndex, value: addCartCount)
                    self?.viewModel?.changeCartCount(cardCountUpdate: cardCountUpdate)
                    
                }.disposed(by: DBag)
        
        // Изменение количества в корзине
        cartCountView.countSubject.subscribe(onNext: { [weak self] value in
            
            // Изменяем значение количества в моделе
            guard let productIndex = self?.productIndex, self?.viewModel != nil else { return }
            
            // Обновляем кнопку в отображении
            let cardCountUpdate = CardCountUpdate(index: productIndex, value: value)
            self?.viewModel?.changeCartCount(cardCountUpdate: cardCountUpdate)
            
        }, onError: { [weak self] error in
            print(error)
        }).disposed(by: DBag)

    }
    
    private func setCartButtons() {

        guard let viewModel = viewModel, let product = viewModel.output.product else { return }

        // Вывод корзины и кол-ва добавленых в корзину
        if product.selectedAmount > 0 {
            
            // Выводим переключатель кол-ва продукта в корзине
            cartBtnDetailView.isHidden = true
            cartCountView.isHidden = false
            
            // Задаем текущее значение счетчика
            cartCountView.count = product.selectedAmount
            
        } else {
            // Выводим кнопку добавления в карзину
            cartBtnDetailView.isHidden = false
            cartCountView.isHidden = true
        }
        
    }
    
    private func changeDescription(text: String) {
        
        // Задаем описание
        if text.isEmpty {
            descriptionLabel.isHidden = true
            descriptionLabel.text = ""
        } else {
            descriptionLabel.isHidden = false
            descriptionLabel.text = text
        }
        
    }
    
    private func updateCartCount(cardCountUpdate: CardCountUpdate) {
        // Записываем новое значение
        cardCountUpdateSubject.onNext(cardCountUpdate)
    }
    
}
