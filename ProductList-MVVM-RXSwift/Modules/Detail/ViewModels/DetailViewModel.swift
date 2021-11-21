
import UIKit
import RxSwift
import RxCocoa

protocol DetailViewModelProtocol {
    var input: InputDetailView { get }
    var output: OutputDetailView { get }
    func changeCartCount(cardCountUpdate: CardCountUpdate)
    func cellViewModel(index: Int) -> DetailCellViewModalProtocol?
}

class DetailViewModel: DetailViewModelProtocol {
    
    let input: InputDetailView
    let output: OutputDetailView

    private let DBag = DisposeBag()

    init() {
        input = InputDetailView()
        output = OutputDetailView()
        
        setupBindings()
    }
    
    private func setupBindings() {
        input.id.subscribe(onNext: { [weak self] id in
            guard let id = id else { return }
            self?.loadProduct(id: id)
        }, onError: { error in
            print(error)
        }).disposed(by: DBag)
    }

    func loadProduct(id: Int) {
        output.image = UIImage(named: "nophoto")!

        // Отправляем запрос загрузки товара
        ProductDetailService.getOneProduct(id: id)
                .subscribe(onNext: { [weak self] product in

                    guard let product = product else { return }
                    
                    // Загрузка изображения, если ссылка пуста, то выводится изображение по умолчанию
                    if !(product.imageUrl.isEmpty) {

                        // Загрузка изображения
                        if let imageURL = URL(string: product.imageUrl) {

                            ImageNetworking.shared.getImage(link: imageURL) { (img) in
                                DispatchQueue.global(qos: .userInitiated).sync {
                                    self?.output.image = img
                                }
                            }

                        }

                    }
                    
                    // Categories
                    if let categories = product.categories {
                        self?.output.categoryListArr = categories
                        self?.output.categoryList.accept(categories)
                    }

                    // Обновляем данные в контроллере
                    self?.output.product = product
                    self?.output.product?.selectedAmount = self?.input.selectedAmount ?? 0
                    self?.output.loaded.onNext(true)

                }, onError: { error in
                    print(error)
                }).disposed(by: DBag)

    }

    func cellViewModel(index: Int) -> DetailCellViewModalProtocol? {
        let category = output.categoryListArr[index]
        return DetailCellViewModel(category: category)
    }

    func changeCartCount(cardCountUpdate: CardCountUpdate) {

        // Обновляем значение
        output.product?.selectedAmount = cardCountUpdate.value
        
        let cardCountUpdate = CardCountUpdate(index: cardCountUpdate.index, value: cardCountUpdate.value)
        output.cardCountUpdateSubject.onNext(cardCountUpdate)

    }
}

class InputDetailView {
    var id = BehaviorRelay<Int?>(value: nil)
    var selectedAmount: Int?
}

class OutputDetailView {
    var product: Product?
    var categoryList = BehaviorRelay<[Category]>(value: [])
    var categoryListArr = [Category]()
    var image: UIImage?
    var loaded = PublishSubject<Bool>()
    var cardCountUpdateSubject = PublishSubject<CardCountUpdate>()
}
