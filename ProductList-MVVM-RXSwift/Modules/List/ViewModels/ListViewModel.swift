
import UIKit
import RxSwift
import RxCocoa

class ListViewModel: ListViewModelProtocol {

    var productList: BehaviorRelay<[Product]>
    var productListArr = [Product]()
    var searchText: PublishSubject<String>
    var showLoadIndicator: PublishSubject<Bool>
    let DBag = DisposeBag()

    // Поиск
    private let searchOperationQueue = OperationQueue()
    var searchString = ""

    // Страницы
    var page: Int = 1
    var haveNextPage: Bool = false

    init() {
        productList = BehaviorRelay<[Product]>(value: [])
        searchText = PublishSubject<String>()
        showLoadIndicator = PublishSubject<Bool>()
        setupBindings()
    }

    private func setupBindings() {

        // Наблюдаем за изменениями в форме поиска
        searchText
                .asObservable()
                .subscribe { [weak self] search in

                    // Проверяем измененный в форме текст
                    guard let searchString = search.element else { return }
                    self?.searchString = searchString
                    
                    // Очищаем старые данные и обновляем таблицу
                    self?.removeAllProducts()

                    // Отображаем анимацию загрузки
                    self?.showLoadIndicator.onNext(true)

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

        // Отправляем запрос загрузки товаров
        ProductNetworking.getProducts(page: page, searchText: searchString)
                .subscribe(onNext: { [weak self] data in

                    // Обрабатываем полученные товары
                    var products = data ?? []

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
                        self?.showLoadIndicator.onNext(false)
                    }

                }, onError: { [weak self] error in
                    print(error)
                }).disposed(by: DBag)

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
