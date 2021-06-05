
import Foundation

protocol DetailViewModelProtocol {
    var title: String { get }
    var producer: String { get }
    var shortDescription: String { get }
    var imageUrl: String { get }
    var price: String { get }
    var categoryList: [Category] { get }
    var selectedAmount: Int { get set }
    func numberOfRows() -> Int
    func cellViewModel(forIndexPath indexPath: IndexPath) -> DetailCellViewModalProtocol?
}
