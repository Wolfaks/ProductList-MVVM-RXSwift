
import UIKit

class ListViewModel: ListViewModelProtocol {

    var productList = [Product]()

    func numberOfRows() -> Int {
        productList.count
    }

    func removeAllProducts() {
        productList.removeAll()
    }

    func appendProducts(products: [Product]) {
        productList.append(contentsOf: products)
    }

    func updateCartCount(index: Int, value: Int) {
        productList[index].selectedAmount = value
    }

    func cellViewModel(forIndexPath indexPath: IndexPath) -> ListCellViewModalProtocol? {
        let product = productList[indexPath.row]
        return ListCellViewModel(product: product)
    }

}
