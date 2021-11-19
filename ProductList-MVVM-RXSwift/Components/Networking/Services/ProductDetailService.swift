
import Foundation
import RxSwift

class ProductDetailService {
    
    private init() {}
    
    static func getOneProduct(id: Int) -> PublishSubject<Product?> {

        let productSubject = PublishSubject<Product?>()
        
        // Подготовка параметров для запроса, задаем выбранный id
        let link = Constants.Urls.product + "\(id)"

        // Подготовка URL
        guard let urlWithParams = NSURLComponents(string: link), let url = urlWithParams.url else { return productSubject }
        
        // Отправляем запрос
        Networking.shared.getData(url: url)
            .subscribe(onNext: { data in
                
                var productResponse = ProductResponse()
                productResponse.decode(data: data)
                
                if let product = productResponse.product {
                    productSubject.onNext(product)
                }
                
            }, onError: { error in
                print(error)
            })

        return productSubject
        
    }
    
}
