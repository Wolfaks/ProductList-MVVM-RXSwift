
import UIKit
import RxCocoa

protocol DetailViewModelProtocol {
    var id: Int { get }
    var title: String { get }
    var producer: String { get }
    var shortDescription: String { get }
    var imageUrl: String { get }
    var image: UIImage { get }
    var price: String { get }
    var categoryList: BehaviorRelay<[Category]> { get }
    var categoryListArr: [Category] { get }
    var selectedAmount: Int { get set }
    var bindToController: () -> () { get set }
    func loadProduct()
    func changeCartCount(index: Int, count: Int)
    func cellViewModel(index: Int) -> DetailCellViewModalProtocol?
}
