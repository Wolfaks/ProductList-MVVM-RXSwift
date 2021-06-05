
import UIKit

class ListViewModel: ListViewModelProtocol {

    var productList = [Product]()
    var haveNextPage:Bool = false
    var bindToController : () -> () = {}

    init(page: Int, searchText: String) {
        loadProducts(page: page, searchText: searchText)
    }

    func loadProducts(page: Int, searchText: String) {

        // Отправляем запрос загрузки товаров
        ProductNetworking.getProducts(page: page, searchText: searchText) { [weak self] (response) in

            // Обрабатываем полученные товары
            var products = response.products

            // Так как API не позвращает отдельный ключ, который говорит о том, что есть следующая страница, определяем это вручную
            if !products.isEmpty && products.count == ProductNetworking.maxProductsOnPage {

                // Задаем наличие следующей страницы
                self?.haveNextPage = true

                // Удаляем последний элемент, который используется только для проверки на наличие следующей страницы
                products.remove(at: products.count - 1)

            }

            // Устанавливаем загруженные товары и обновляем таблицу
            // append contentsOf так как у нас метод грузит как первую страницу, так и последующие
            self?.appendProducts(products: products)

            // Обновляем данные в контроллере
            self?.bindToController()

        }

    }

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
