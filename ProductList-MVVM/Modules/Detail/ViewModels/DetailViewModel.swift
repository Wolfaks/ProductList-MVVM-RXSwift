
import UIKit

class DetailViewModel: DetailViewModelProtocol {

    let id: Int

    var title: String = ""
    var producer: String = ""
    var shortDescription: String = ""
    var imageUrl: String = ""
    var price: String = ""
    var categoryList: [Category] = []
    var selectedAmount: Int = 0

    var bindToController : () -> () = {}

    init(productID: Int, amount: Int) {
        id = productID
        selectedAmount = amount
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
                self?.categoryList = product.categories

                // Обновляем данные в контроллере
                self?.bindToController()

            }

        }

    }

    func numberOfRows() -> Int {
        categoryList.count
    }

    func cellViewModel(forIndexPath indexPath: IndexPath) -> DetailCellViewModalProtocol? {
        let category = categoryList[indexPath.row]
        return DetailCellViewModel(category: category)
    }

}
