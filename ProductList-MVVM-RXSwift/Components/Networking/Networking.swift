
import UIKit
import RxSwift
import RxCocoa

class Networking {

    enum LinkList: String {
        case list = "https://rstestapi.redsoftdigital.com/api/v1/products"
        case product = "https://rstestapi.redsoftdigital.com/api/v1/products/"
    }

    // Создаем синглтон для обращения к методам класса
    private init() {
    }
    static let shared = Networking()

    public func getData(url: URL) -> Observable<Any> {

        let session = URLSession.shared

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        // Выполняем запрос по URL
        return session.rx.data(request: urlRequest)
                .map {
                    try JSONSerialization.jsonObject(with: $0, options: [])
                }
                .observeOn(MainScheduler.asyncInstance)
    }

}
