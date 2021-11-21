
import UIKit
import RxSwift
import RxCocoa

protocol ListViewModelProtocol: class {
    var input: InputListView { get }
    var output: OutputListView { get }
    func visibleCell(index: Int)
    func updateCartCount(cardCountUpdate: CardCountUpdate)
    func cellViewModel(product: Product) -> ListCellViewModalProtocol?
}

class ListViewModel: ListViewModelProtocol {

    private let DBag = DisposeBag()

    // Поиск
    private let searchOperationQueue = OperationQueue()
    
    private var lastID: Int = 0
    private var page: Int = 1
    
    let input: InputListView
    let output: OutputListView

    init() {
        input = InputListView()
        output = OutputListView()
        setupBindings()
    }

    private func setupBindings() {

        // Наблюдаем за изменениями в форме поиска
        input.searchSubject
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
        
        lastID = 0

        // Отправляем запрос загрузки товаров
        ProductListService.getProducts(page: self.page, searchText: self.input.searchText)
                .subscribe(onNext: { [weak self] productsRaw in

                    var products = productsRaw
                    
                    // Так как API не позвращает отдельный ключ, который говорит о том, что есть следующая страница, определяем это вручную
                    if !products.isEmpty && products.count == Constants.Settings.maxProductsOnPage {
                        
                        // Удаляем последний элемент, который используется только для проверки на наличие следующей страницы
                        products.remove(at: products.count - 1)
                        
                        // Получаем id последнего продукта
                        self?.lastID = products.last?.id ?? 0

                    }

                    // Устанавливаем загруженные товары и обновляем таблицу
                    // append contentsOf так как у нас метод грузит как первую страницу, так и последующие
                    self?.appendProducts(products: products)

                    // Обновляем данные в контроллере
                    if self?.page == 1 {
                        self?.output.showLoadIndicator.onNext(false)
                    }

                }, onError: { error in
                    print(error)
                }).disposed(by: DBag)

    }

    func visibleCell(index: Int) {

        let productList = output.productList.value
        guard !productList.isEmpty && productList.indices.contains(index) else { return }
        
        // Проверяем что оторазили последний элемент и если есть, отображаем следующую страницу
        if lastID > 0 && lastID == productList[index].id {

            // Задаем новую страницу
            self.page += 1

            // Запрос данных
            loadProducts()

        }

    }

    private func removeAllProducts() {
        output.productList.accept([])
    }

    private func appendProducts(products: [Product]) {
        var oldProducts = output.productList.value
        oldProducts.append(contentsOf: products)
        output.productList.accept(oldProducts)
    }
    
    private func updateProducts(products: [Product]) {
        output.productList.accept(products)
    }

    func updateCartCount(cardCountUpdate: CardCountUpdate) {
        var productList = output.productList.value
        guard !productList.isEmpty && productList.indices.contains(cardCountUpdate.index) else { return }
        
        productList[cardCountUpdate.index].selectedAmount = cardCountUpdate.value
        updateProducts(products: productList)
    }

    func cellViewModel(product: Product) -> ListCellViewModalProtocol? {
        ListCellViewModel(product: product)
    }

}

class InputListView {
    var searchSubject = PublishSubject<String>()
    var searchText: String = ""
}

class OutputListView {
    var productList = BehaviorRelay<[Product]>(value: [])
    var showLoadIndicator = PublishSubject<Bool>()
    var reload: Bool?
    var selectProductIndex = PublishSubject<Int>()
}
