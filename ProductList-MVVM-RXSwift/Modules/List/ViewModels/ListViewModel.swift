
import UIKit
import RxSwift
import RxCocoa

class ListViewModel: ListViewModelProtocol {

    var productList: BehaviorRelay<[Product]>
    var productListArr = [Product]()
    var searchText: BehaviorRelay<String>
    var showLoadIndicator: () -> () = {}
    var hideLoadIndicator: () -> () = {}
    let DBag = DisposeBag()

    // Поиск
    var searchString = ""
    private let searchOperationQueue = OperationQueue()

    // Страницы
    var page: Int = 1
    var haveNextPage: Bool = false

    init() {
        productList = BehaviorRelay<[Product]>(value: [])
        searchText = BehaviorRelay<String>(value: "")
        searchObservable()
        loadProducts()
    }

    func searchObservable() {
        // Наблюдаем за изменениями в форме поиска
        searchText
                .asObservable()
                .subscribe { [weak self] (search) in

                    // Проверяем измененный в форме текст
                    guard let searchString = search.element else { return }

                    // Выполняем поиск когда форма была изменена
                    if searchString.hash == self?.searchString.hash {
                        return
                    }

                    // Получаем искомую строку
                    self?.searchString = searchString

                    // Очищаем старые данные и обновляем таблицу
                    self?.removeAllProducts()

                    // Отображаем анимацию загрузки
                    self?.showLoadIndicator()

                    // Поиск с задержкой (по ТЗ)
                    let operationSearch = BlockOperation()
                    operationSearch.addExecutionBlock { [weak operationSearch] in

                        // Задержка (по ТЗ)
                        sleep(2)

                        if !(operationSearch?.isCancelled ?? false) {

                            // Выполняем поиск
                            // Задаем первую страницу
                            self?.page = 1

                            // Запрос данных
                            self?.loadProducts()

                        }

                    }
                    self?.searchOperationQueue.cancelAllOperations()
                    self?.searchOperationQueue.addOperation(operationSearch)

                }.disposed(by: DBag)
    }

    func loadProducts() {

        // Отправляем запрос загрузки товаров
        ProductNetworking.getProducts(page: page, searchText: searchText.value) { [weak self] (response) in

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
            if self?.page == 1 {
                self?.hideLoadIndicator()
            }

        }

    }

    func visibleCell(Index: Int) {

        // Проверяем что оторазили последний элемент и если есть, отображаем следующую страницу
        if !productListArr.isEmpty && (productListArr.count - 1) == Index, haveNextPage {

            // Задаем новую страницу
            haveNextPage = false
            page += 1

            // Запрос данных
            loadProducts()

        }

    }

    func removeAllProducts() {
        productListArr.removeAll()
        productList.accept(productListArr)
    }

    func updateProducts() {
        productList.accept(productListArr)
    }

    func appendProducts(products: [Product]) {
        productListArr.append(contentsOf: products)
        productList.accept(productListArr)
    }

    func updateCartCount(index: Int, value: Int) {
        guard !productListArr.isEmpty && productListArr.indices.contains(index) else { return }
        productListArr[index].selectedAmount = value
        updateProducts()
    }

    func cellViewModel(product: Product) -> ListCellViewModalProtocol? {
        ListCellViewModel(product: product)
    }

}
