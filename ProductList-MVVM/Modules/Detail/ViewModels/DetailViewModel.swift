
import UIKit

class DetailViewModel: DetailViewModelProtocol {

    var title: String
    var producer: String
    var shortDescription: String
    var imageUrl: String
    var price: String
    var categoryList: [Category]
    var selectedAmount: Int

    init(product: Product, amount: Int) {
        title = product.title
        producer = product.producer
        shortDescription = product.shortDescription
        imageUrl = product.imageUrl

        // Убираем лишние нули после запятой, если они есть и выводим цену
        price = String(format: "%g", product.price) + " ₽"

        categoryList = product.categories
        selectedAmount = amount
    }

    func numberOfRows() -> Int {
        categoryList.count
    }

    func cellViewModel(forIndexPath indexPath: IndexPath) -> DetailCellViewModalProtocol? {
        let category = categoryList[indexPath.row]
        return DetailCellViewModel(category: category)
    }

}
