
import Foundation

protocol ListViewModelProtocol {
    var productList: [Product] { get }
    func numberOfRows() -> Int
    func removeAllProducts()
    func appendProducts(products: [Product])
    func updateCartCount(index: Int, value: Int)
    func cellViewModel(forIndexPath indexPath: IndexPath) -> ListCellViewModalProtocol?
}
