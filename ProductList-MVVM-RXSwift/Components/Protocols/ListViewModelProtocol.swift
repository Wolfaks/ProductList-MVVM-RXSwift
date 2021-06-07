
import Foundation
import RxCocoa

protocol ListViewModelProtocol {
    var productList: BehaviorRelay<[Product]> { get }
    var productListArr: [Product] { get }
    var searchText: BehaviorRelay<String> { get }
    var page: Int { get set }
    var haveNextPage: Bool { get set }
    var showLoadIndicator: () -> () { get set }
    var hideLoadIndicator: () -> () { get set }
    func loadProducts()
    func visibleCell(Index: Int)
    func removeAllProducts()
    func updateProducts()
    func appendProducts(products: [Product])
    func updateCartCount(index: Int, value: Int)
    func cellViewModel(product: Product) -> ListCellViewModalProtocol?
}
