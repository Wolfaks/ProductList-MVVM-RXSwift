
import UIKit
import RxSwift
import RxCocoa

protocol ListViewModelProtocol: class {
    var input: InputListView { get }
    var output: OutputListView { get }
    var searchText: PublishSubject<String> { get }
    func visibleCell(Index: Int)
    func updateCartCount(cardCountUpdate: CardCountUpdate)
    func cellViewModel(product: Product) -> ListCellViewModalProtocol?
}

class ListViewModel: ListViewModelProtocol {

    var searchText: PublishSubject<String>
    let DBag = DisposeBag()

    // Поиск
    private let searchOperationQueue = OperationQueue()
    
    let input: InputListView
    let output: OutputListView

    init() {
        input = InputListView()
        output = OutputListView()
        
        searchText = PublishSubject<String>()
        setupBindings()
    }

    private func setupBindings() {

        // Наблюдаем за изменениями в форме поиска
        searchText
                .asObservable()
                .subscribe { [weak self] search in

                    // Проверяем измененный в форме текст
                    guard let searchString = search.element else { return }
                    self?.input.searchText = searchString
                    
                    // Очищаем старые данные и обновляем таблицу
                    self?.removeAllProducts()

                    // Отображаем анимацию загрузки
                    self?.output.showLoadIndicator.onNext(true)

                    // Поиск
                    let operationSearch = BlockOperation()
                    operationSearch.addExecutionBlock { [weak operationSearch] in

                        if !(operationSearch?.isCancelled ?? false) {

                            // Выполняем поиск
                            // Задаем первую страницу
                            self?.input.page = 1

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
        ProductListService.getProducts(page: self.input.page, searchText: self.input.searchText)
                .subscribe(onNext: { [weak self] productsRaw in

                    var products = productsRaw
                    
                    // Так как API не позвращает отдельный ключ, который говорит о том, что есть следующая страница, определяем это вручную
                    if !products.isEmpty && products.count == Constants.Settings.maxProductsOnPage {

                        // Задаем наличие следующей страницы
                        self?.input.haveNextPage = true

                        // Удаляем последний элемент, который используется только для проверки на наличие следующей страницы
                        products.remove(at: products.count - 1)

                    }

                    // Устанавливаем загруженные товары и обновляем таблицу
                    // append contentsOf так как у нас метод грузит как первую страницу, так и последующие
                    self?.appendProducts(products: products)

                    // Обновляем данные в контроллере
                    if self?.input.page == 1 {
                        self?.output.showLoadIndicator.onNext(false)
                    }

                }, onError: { error in
                    print(error)
                }).disposed(by: DBag)

    }

    func visibleCell(Index: Int) {

        // Проверяем что оторазили последний элемент и если есть, отображаем следующую страницу
        if !output.productListArr.isEmpty && (output.productListArr.count - 1) == Index, self.input.haveNextPage {

            // Задаем новую страницу
            self.input.haveNextPage = false
            self.input.page += 1

            // Запрос данных
            loadProducts()

        }

    }

    private func removeAllProducts() {
        output.productListArr.removeAll()
        output.productList.accept(output.productListArr)
    }

    private func updateProducts() {
        output.productList.accept(output.productListArr)
    }

    private func appendProducts(products: [Product]) {
        output.productListArr.append(contentsOf: products)
        output.productList.accept(output.productListArr)
    }

    func updateCartCount(cardCountUpdate: CardCountUpdate) {
        guard !output.productListArr.isEmpty && output.productListArr.indices.contains(cardCountUpdate.index) else { return }
        output.productListArr[cardCountUpdate.index].selectedAmount = cardCountUpdate.value
        updateProducts()
    }

    func cellViewModel(product: Product) -> ListCellViewModalProtocol? {
        ListCellViewModel(product: product)
    }

}

class InputListView {
    var searchText: String = ""
    var page: Int = 1
    var haveNextPage: Bool = false
}

class OutputListView {
    var productListArr = [Product]()
    var productList = BehaviorRelay<[Product]>(value: [])
    var showLoadIndicator = PublishSubject<Bool>()
    var reload: Bool?
    var selectProductIndex = PublishSubject<Int>()
}
