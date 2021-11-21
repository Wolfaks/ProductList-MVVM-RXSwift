
import UIKit
import RxCocoa
import RxSwift

class ListViewController: UIViewController {

    @IBOutlet weak var searchForm: UITextField!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadIndicator: UIActivityIndicatorView!

    // viewModel
    var viewModel: ListViewModelProtocol!
    private let DBag = DisposeBag()
    
    weak var detailViewController: DetailViewControllerProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingUI()
        setupBindings()
    }
    
    private func settingUI() {

        // viewModel
        viewModel = ListViewModel()

        // searchForm
        searchForm.delegate = self
        
    }

    private func setupBindings() {
        bindViewToViewModel()
        bindViewModelToView()
    }

    private func bindViewToViewModel() {

        // Связываем TextField с поисков в ListViewModel
        searchForm.rx.text
            .orEmpty
            .throttle(.milliseconds(1000), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
            .do(onNext: nil)
                .bind(to: viewModel.input.searchSubject)
            .disposed(by: DBag)

    }

    private func bindViewModelToView() {

        // Вывод данных
        viewModel.output.productList.bind(to: tableView.rx.items(cellIdentifier: "productCell", cellType: ProductListTableCell.self)) {
            (row, item, cell) in

            let cellViewModel = self.viewModel.cellViewModel(product: item)
            cell.productIndex = row
            cell.viewModel = cellViewModel
            cell.listViewModel = self.viewModel

        }.disposed(by: DBag)

        // Индекс отображаемых ячеек
        tableView.rx
                .willDisplayCell
                .asObservable()
                .subscribe { [weak self] ( _, indexPath) in

                    // Проверяем что оторазили последний элемент и если есть, отображаем следующую страницу
                    guard self?.viewModel != nil else { return }
                    self?.viewModel.visibleCell(index: indexPath.row)

                }.disposed(by: DBag)

        // Анимация загрузки
        viewModel.output.showLoadIndicator.subscribe(onNext: { [weak self] show in

            if show {
                // Отображаем анимацию загрузки
                self?.loadIndicator.startAnimating()
            } else {
                // Скрываем анимацию загрузки
                self?.loadIndicator.stopAnimating()
            }

        }, onError: { error in
            print(error)
        }).disposed(by: DBag)
        
        viewModel?.output.selectProductIndex.subscribe(onNext: { [weak self] index in
            self?.redirectToDetail(index: index)
        }, onError: { error in
            print(error)
        }).disposed(by: DBag)

    }
    
    private func bindDetailUpdateCard() {
        self.detailViewController?.cardCountUpdateSubject.subscribe(onNext: { [weak self] cardCountUpdate in

            // Вывод корзины и кол-ва добавленых в корзину
            self?.updateCartCount(cardCountUpdate: cardCountUpdate)

        }, onError: { error in
            print(error)
        }).disposed(by: DBag)
    }
    
    private func redirectToDetail(index: Int) {
        
        // Выполняем переход в детальную информацию
        let productList = viewModel.output.productList.value
        if !productList.indices.contains(index) { return }
        
        // Выполняем переход в детальную информацию
        detailViewController = DetailViewController.storyboardInstance()
        if let detailViewController = detailViewController as? UIViewController {
            self.detailViewController?.setProductData(productIndex: index,
                                                      productID: productList[index].id,
                                                      productTitle: productList[index].title,
                                                      productSelectedAmount: productList[index].selectedAmount)
            
            bindDetailUpdateCard()
            
            navigationController?.pushViewController(detailViewController, animated: true)
        }
        
    }
    
    @IBAction func removeSearch(_ sender: Any) {
        
        // Очищаем форму поиска
        searchForm.text = ""
        
        // Скрываем клавиатуру
        hideKeyboard()
        
    }
    
    private func updateCartCount(cardCountUpdate: CardCountUpdate) {
        viewModel.updateCartCount(cardCountUpdate: cardCountUpdate)
    }
    
    private func hideKeyboard() {
        view.endEditing(true)
    }
    
}

extension ListViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == searchForm {
            // Скрываем клавиатуру при нажатии на клавишу Done / Готово
            hideKeyboard()
        }
        
        return true
        
    }
    
}
