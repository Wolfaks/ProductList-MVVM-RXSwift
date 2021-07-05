
import Foundation
import RxSwift

class ProductNetworking {

    // Задаем максимальное количество элементов на странице статической константой, чтобы обращаться из других класов
    static let maxProductsOnPage = 21
    
    private init() {}
    
    static func getProducts(page: Int, searchText: String) -> PublishSubject<[Product]> {
        
        // Подготовка параметров для запроса, задаем макс количество элементов = 21
        var params = ["maxItems": "\(maxProductsOnPage)"]
        let products = PublishSubject<[Product]>()

        // Страница
        var startFrom = 0
        if page > 0 {
            startFrom = ((page - 1) * (maxProductsOnPage - 1));
        }
        params["startFrom"] = "\(startFrom)"

        // Поиск
        if !searchText.isEmpty {
            params["filter[title]"] = searchText
        }

        // Подготовка URL
        if let urlWithParams = NSURLComponents(string: Networking.LinkList.list.rawValue) {

            // Параметры запроса
            var parameters = [URLQueryItem]()
            for (key, value) in params {
                parameters.append(URLQueryItem(name: key, value: value))
            }

            if !parameters.isEmpty {
                urlWithParams.queryItems = parameters
            }
            // END Параметры запроса

            if let url = urlWithParams.url {

                // Получаем список
                Networking.network.getData(url: url)
                        .subscribe(onNext: { data in

                            do {
                                let response = try ProductResponse(products: data)
                                products.onNext(response.products)
                            } catch {
                                print(error)
                            }

                        }, onError: { error in
                            print(error)
                        })

            }

        }

        return products
        
    }
    
    static func getOneProduct(id: Int) -> PublishSubject<Product?> {

        let product = PublishSubject<Product?>()
        
        // Подготовка параметров для запроса, задаем выбранный id
        let link = Networking.LinkList.product.rawValue + "\(id)"

        // Подготовка URL
        if let urlWithParams = NSURLComponents(string: link) {

            if let url = urlWithParams.url {

                // Получаем список
                Networking.network.getData(url: url)
                        .subscribe(onNext: { data in

                            do {
                                let response = try ProductResponse(product: data)
                                product.onNext(response.product)
                            } catch {
                                print(error)
                            }

                        }, onError: { error in
                            print(error)
                        })

            }

        }

        return product
        
    }
    
}
