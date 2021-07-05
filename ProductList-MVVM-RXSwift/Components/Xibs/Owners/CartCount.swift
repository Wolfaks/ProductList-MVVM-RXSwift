
import UIKit
import RxSwift

@IBDesignable class CartCount: UIView {

    static let widthSize: CGFloat = 92.0
    static let heightSize: CGFloat = 28.0

    @IBOutlet weak var radiusStackView: UIStackView!
    @IBOutlet weak var minusBtn: UIButton!
    @IBOutlet weak var plusBtn: UIButton!
    @IBOutlet weak var selectedAmount: UILabel!
    
    var countSubject = PublishSubject<Int>()
    var count: Int = 0 {
        didSet {
            selectedAmount.text = "\(count)"
        }
    }
    
    var view: UIView!
    var nibName: String = "CartCount"
    
    let DBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func loadFromNib() -> UIView {
        
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: String(describing: type(of: self)), bundle: bundle)
        let view = nib.instantiate(withOwner: self, options: nil)[0] as! UIView
        return view
        
    }
    
    func setupView() {
        let view = loadFromNib()
        view.frame = bounds
        view.autoresizingMask = [
            UIView.AutoresizingMask.flexibleWidth,
            UIView.AutoresizingMask.flexibleHeight
        ]
        addSubview(view)
        
        // Закругляем углы stackView
        radiusStackView.layer.cornerRadius = 5.0
        
        // bind - Клик на кнопки количества товаров в корзине
        setupBindings()
        
    }
    
    private func setupBindings() {
        
        // bind - Клик на кнопки количества товаров в корзине
        
        // Нажали на кнопку минус
        minusBtn.rx.tap
                .subscribe { [weak self] tap in
                    // Нельзя задавать значение меньше нуля
                    self?.countSubject.onNext(max(0, (self?.count ?? 0) - 1))
                }.disposed(by: DBag)
        
        // Нажали на кнопку плюс
        plusBtn.rx.tap
                .subscribe { [weak self] tap in
                    self?.countSubject.onNext((self?.count ?? 0) + 1)
                }.disposed(by: DBag)
        
        // Изменение количества в корзине
        countSubject.subscribe(onNext: { [weak self] count in
            self?.count = count
        }, onError: { [weak self] error in
            print(error)
        }).disposed(by: DBag)
        
    }
    
}
