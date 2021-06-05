
import Foundation

protocol ListViewModelProtocol {
    var productList: [Product] { get }
    var haveNextPage: Bool { get set }
    var bindToController: () -> () { get set }
    func loadProducts(page: Int, searchText: String)
    func numberOfRows() -> Int
    func removeAllProducts()
    func appendProducts(products: [Product])
    func updateCartCount(index: Int, value: Int)
    func cellViewModel(forIndexPath indexPath: IndexPath) -> ListCellViewModalProtocol?
}
