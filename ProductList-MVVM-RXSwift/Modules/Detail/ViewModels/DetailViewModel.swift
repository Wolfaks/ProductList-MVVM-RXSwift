
import UIKit
import RxSwift
import RxCocoa

class DetailViewModel: DetailViewModelProtocol {

    let id: Int

    var title: String = ""
    var producer: String = ""
    var shortDescription: String = ""
    var imageUrl: String = ""
    var image: UIImage
    var price: String = ""
    var categoryList: BehaviorRelay<[Category]>
    var categoryListArr = [Category]()
    var selectedAmount: Int = 0

    var bindToController : () -> () = {}

    init(productID: Int, amount: Int) {
        id = productID
        selectedAmount = amount
        image = UIImage(named: "nophoto")!
        categoryList = BehaviorRelay<[Category]>(value: [])
        loadProduct()
    }

    func loadProduct() {

        // Отправляем запрос загрузки товара
        ProductNetworking.getOneProduct(id: id) { [weak self] (response) in

            // Проверяем что данные были успешно обработаны
            if let product = response.product {

                self?.title = product.title
                self?.producer = product.producer
                self?.shortDescription = product.shortDescription
                self?.imageUrl = product.imageUrl

                // Убираем лишние нули после запятой, если они есть и выводим цену
                self?.price = String(format: "%g", product.price) + " ₽"

                // categories
                self?.categoryListArr = product.categories
                self?.categoryList.accept(product.categories)

                // Загрузка изображения, если ссылка пуста, то выводится изображение по умолчанию
                if !(self?.imageUrl.isEmpty ?? false) {

                    // Загрузка изображения
                    if let imageURL = URL(string: (self?.imageUrl)!) {

                        ImageNetworking.networking.getImage(link: imageURL) { (img) in
                            DispatchQueue.global(qos: .userInitiated).sync {
                                self?.image = img
                            }
                        }

                    }

                }

                // Обновляем данные в контроллере
                self?.bindToController()

            }

        }

    }

    func cellViewModel(index: Int) -> DetailCellViewModalProtocol? {
        let category = categoryListArr[index]
        return DetailCellViewModel(category: category)
    }

    func changeCartCount(index: Int, count: Int) {

        // Обновляем значение
        selectedAmount = count

        // Обновляем значение в корзине в списке через наблюдатель
        NotificationCenter.default.post(name: Notification.Name(rawValue: "notificationUpdateCartCount"), object: nil, userInfo: ["index": index, "count": count])

    }
}
