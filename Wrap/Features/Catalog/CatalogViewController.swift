import UIKit
import SnapKit
import Kingfisher
import Hero
import RxSwift
import RxCocoa

protocol ProductCellDelegate: AnyObject {
    func productCell(_ cell: ProductCell, didUpdateQuantity quantity: Int, for product: Product)
}

class ProductCell: UITableViewCell {
    static let identifier = "ProductCell"

    weak var delegate: ProductCellDelegate?
    private var product: Product?

    private let containerView = UIView()

    let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader()
        return label
    }()

    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.price()
        label.textColor = Brand.Text.primary
        return label
    }()
    
    private let stepper = InteractiveStepper()
    
    private let outOfStockOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground.withAlphaComponent(0.6)
        view.isHidden = true
        
        let label = UILabel()
        label.text = "Out of Stock"
        label.font = Brand.Typography.caption()
        label.textColor = .systemRed
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.backgroundColor = .systemBackground
        containerView.roundCorners(radius: 16)
        
        containerView.addSubview(productImageView)
        
        let stackView = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        containerView.addSubview(stackView)
        
        containerView.addSubview(stepper)
        stepper.delegate = self
        
        containerView.addSubview(outOfStockOverlay)
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        productImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(12)
            make.size.equalTo(80)
        }
        
        stepper.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(32)
            make.width.equalTo(100)
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(productImageView.snp.trailing).offset(16)
            make.trailing.equalTo(stepper.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        
        outOfStockOverlay.snp.makeConstraints { make in
            make.edges.equalTo(stepper)
        }
    }
    
    func configure(with product: Product) {
        self.product = product
        nameLabel.text = product.name
        priceLabel.text = product.basePrice.formattedIDR
        
        productImageView.hero.id = "image_\(product.id.uuidString)"
        nameLabel.hero.id = "title_\(product.id.uuidString)"
        
        let firstVariant = product.variants?.first
        let stock = firstVariant?.qtyOnHand ?? 0
        let isOutOfStock = stock <= 0
        
        outOfStockOverlay.isHidden = !isOutOfStock
        stepper.isUserInteractionEnabled = !isOutOfStock
        
        if let variantId = firstVariant?.id {
            let currentQty = CartManager.shared.quantity(for: variantId)
            stepper.setValue(currentQty)
        } else {
            stepper.setValue(0)
        }
        
        if let imageUrlString = product.images?.first, let url = URL(string: imageUrlString) {
            productImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            productImageView.image = UIImage(systemName: "photo")
        }
    }
}

extension ProductCell: InteractiveStepperDelegate {
    func stepper(_ stepper: InteractiveStepper, didUpdateValue value: Int) {
        guard let product = product else { return }
        delegate?.productCell(self, didUpdateQuantity: value, for: product)
    }
}

@MainActor
class CatalogViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let productsRelay = BehaviorRelay<[Product]>(value: [])
    private var category: CatalogCategory?
    private let disposeBag = DisposeBag()
    
    init(category: CatalogCategory? = nil) {
        self.category = category
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .secondarySystemBackground
        return tv
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCatalog()
        setupBindings()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupBindings() {
        // Bind products to TableView
        productsRelay
            .bind(to: tableView.rx.items(cellIdentifier: ProductCell.identifier, cellType: ProductCell.self)) { [weak self] _, product, cell in
                cell.configure(with: product)
                cell.delegate = self
            }
            .disposed(by: disposeBag)
        
        // Handle selection
        tableView.rx.modelSelected(Product.self)
            .subscribe(onNext: { [weak self] product in
                self?.coordinator?.showProductDetail(productId: product.id)
            })
            .disposed(by: disposeBag)
        
        // Bind cart updates to UI
        CartManager.shared.cartItems
            .subscribe(onNext: { [weak self] _ in
                self?.updateCartBadge()
                self?.tableView.reloadData() // Still need reloadData to refresh stepper values in cells
            })
            .disposed(by: disposeBag)
    }
    
    private func updateCartBadge() {
        let count = CartManager.shared.totalCount
        if let cartTab = tabBarController?.tabBar.items?[1] {
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }
    
    private func setupUI() {
        title = category?.name ?? "Wrap"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .secondarySystemBackground
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.identifier)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        updateCartBadge()
    }
    
    private func fetchCatalog() {
        activityIndicator.startAnimating()
        Task {
            do {
                let fetchedProducts = try await CatalogService.shared.fetchProducts(categoryId: category?.id)
                activityIndicator.stopAnimating()
                self.productsRelay.accept(fetchedProducts)
            } catch {
                activityIndicator.stopAnimating()
                print("Failed to fetch catalog: \(error)")
            }
        }
    }
}

extension CatalogViewController: ProductCellDelegate {
    func productCell(_ cell: ProductCell, didUpdateQuantity quantity: Int, for product: Product) {
        guard let firstVariant = product.variants?.first else { return }
        let price = firstVariant.priceOverride ?? product.basePrice
        
        CartManager.shared.setQuantity(variantId: firstVariant.id, quantity: quantity, name: product.name, price: price)
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CatalogViewController())
}
