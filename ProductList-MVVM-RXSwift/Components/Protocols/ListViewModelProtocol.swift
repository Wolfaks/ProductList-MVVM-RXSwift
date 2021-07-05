
import Foundation
import RxSwift
import RxCocoa

protocol ListViewModelProtocol {
    var productList: BehaviorRelay<[Product]> { get }
    var productListArr: [Product] { get }
    var searchText: PublishSubject<String> { get }
    var page: Int { get set }
    var searchString: String { get set }
    var haveNextPage: Bool { get set }
    var showLoadIndicator: PublishSubject<Bool> { get set }
    func loadProducts()
    func visibleCell(Index: Int)
    func removeAllProducts()
    func updateProducts()
    func appendProducts(products: [Product])
    func updateCartCount(index: Int, value: Int)
    func cellViewModel(product: Product) -> ListCellViewModalProtocol?
}
