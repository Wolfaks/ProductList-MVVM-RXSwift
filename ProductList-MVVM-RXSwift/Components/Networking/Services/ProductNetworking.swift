
import Foundation
import RxSwift

class ProductListService {
    
    private init() {}
    
    static func getProducts(page: Int, searchText: String) -> PublishSubject<[Product]> {
        
        // Подготовка параметров для запроса, задаем макс количество элементов = 21
        var params = ["maxItems": "\(Constants.Settings.maxProductsOnPage)"]
        let productsSubject = PublishSubject<[Product]>()

        // Страница
        var startFrom = 0
        if page > 0 {
            startFrom = ((page - 1) * (Constants.Settings.maxProductsOnPage - 1));
        }
        params["startFrom"] = "\(startFrom)"

        // Поиск
        if !searchText.isEmpty {
            params["filter[title]"] = searchText
        }

        // Подготовка URL
        guard let urlWithParams = NSURLComponents(string: Constants.Urls.productsList) else { return productsSubject }
        
        // Параметры запроса
        var parameters = [URLQueryItem]()
        for (key, value) in params {
            parameters.append(URLQueryItem(name: key, value: value))
        }
        
        if !parameters.isEmpty {
            urlWithParams.queryItems = parameters
        }
        // END Параметры запроса
        
        guard let url = urlWithParams.url else { return productsSubject }
        
        // Отправляем запрос
        Networking.shared.getData(url: url)
            .subscribe(onNext: { data in
                
                var productListResponse = ProductListResponse()
                productListResponse.decode(data: data)
                productsSubject.onNext(productListResponse.products)
                
            }, onError: { error in
                print(error)
            })
        
        return productsSubject
        
    }
    
}
