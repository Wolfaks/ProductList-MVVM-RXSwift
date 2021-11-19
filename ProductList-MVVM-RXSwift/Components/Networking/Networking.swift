
import UIKit
import RxSwift
import RxCocoa

class Networking {

    // Создаем синглтон для обращения к методам класса
    private init() {}
    static let shared = Networking()

    public func getData(url: URL) -> Observable<Data> {

        let session = URLSession.shared

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "GET"

        // Выполняем запрос по URL
        return session.rx.data(request: urlRequest)
                .observeOn(MainScheduler.asyncInstance)
    }

}
