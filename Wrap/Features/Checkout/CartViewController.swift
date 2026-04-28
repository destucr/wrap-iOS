import UIKit
import SnapKit

class CartItemCell: UITableViewCell {
    static let identifier = "CartItemCell"
    
    private let containerView = UIView()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 16)
        return label
    }()
    
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 16)
        label.textColor = Brand.primary
        return label
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
        containerView.roundCorners(radius: 12)
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(priceLabel)
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        quantityLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.bottom.equalToSuperview().inset(16)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }
    
    func configure(with item: CartItem) {
        nameLabel.text = item.name
        quantityLabel.text = "Quantity: \(item.quantity)"
        priceLabel.text = "Rp \(Int(item.price * Double(item.quantity)))"
    }
}

class CartViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var recommendations: [Product] = []
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .secondarySystemBackground
        return tv
    }()
    
    private let checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Proceed to Checkout", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.roundCorners(radius: 16)
        button.titleLabel?.font = Brand.Typography.subheader()
        return button
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.header(size: 22)
        label.textAlignment = .right
        return label
    }()
    
    private let emptyStateView = EmptyCartView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
        fetchRecommendations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        updateUIState()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
    }
    
    @objc private func cartDidUpdate() {
        updateUIState()
    }
    
    private func setupUI() {
        title = "My Cart"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .secondarySystemBackground
        
        view.addSubview(tableView)
        view.addSubview(totalLabel)
        view.addSubview(checkoutButton)
        view.addSubview(emptyStateView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.identifier)
        
        checkoutButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.bottom.equalTo(checkoutButton.snp.top).offset(-24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(totalLabel.snp.top).offset(-12)
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        emptyStateView.shopButton.addTarget(self, action: #selector(handleMulaiBelanja), for: .touchUpInside)
        checkoutButton.addTarget(self, action: #selector(handleCheckout), for: .touchUpInside)
        
        emptyStateView.recommendationsCollectionView.delegate = self
        emptyStateView.recommendationsCollectionView.dataSource = self
    }
    
    private func fetchRecommendations() {
        Task {
            do {
                let products: [Product] = try await NetworkManager.shared.request(endpoint: "/catalog/products")
                self.recommendations = Array(products.prefix(10))
                self.emptyStateView.recommendationsCollectionView.reloadData()
            } catch {
                print("Failed to fetch recommendations: \(error)")
            }
        }
    }
    
    private func updateUIState() {
        let items = CartManager.shared.items
        let isEmpty = items.isEmpty
        
        tableView.isHidden = isEmpty
        totalLabel.isHidden = isEmpty
        checkoutButton.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        if isEmpty {
            navigationItem.title = ""
            navigationItem.largeTitleDisplayMode = .never
        } else {
            navigationItem.title = "My Cart"
            navigationItem.largeTitleDisplayMode = .always
            tableView.reloadData()
            totalLabel.text = "Total: Rp \(Int(CartManager.shared.totalAmount))"
            checkoutButton.isEnabled = true
            checkoutButton.alpha = 1.0
        }
        
        // Update tab badge
        if let cartTab = tabBarController?.tabBar.items?[1] {
            let count = CartManager.shared.totalCount
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }
    
    @objc private func handleMulaiBelanja() {
        coordinator?.showCatalog()
    }
    
    @objc private func handleCheckout() {
        Task {
            do {
                try await CartManager.shared.syncWithBackend()
                coordinator?.showCheckoutPreview()
            } catch {
                let alert = UIAlertController(title: "Error", message: "Could not sync your cart. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
}

extension CartViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CartManager.shared.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CartItemCell.identifier, for: indexPath) as? CartItemCell else {
            return UITableViewCell()
        }
        cell.configure(with: CartManager.shared.items[indexPath.row])
        return cell
    }
}

extension CartViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
        cell.configure(with: recommendations[indexPath.item])
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = recommendations[indexPath.item]
        coordinator?.showProductDetail(productId: product.id)
    }
}

// MARK: - Empty State View
final class EmptyCartView: UIView {
    
    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "cart.badge.minus"))
        iv.tintColor = .systemGray4
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Keranjang kamu masih kosong"
        label.font = Brand.Typography.header(size: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ayo isi dengan produk-produk pilihan terbaik untuk kebutuhan harianmu."
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    let shopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Mulai Belanja", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.roundCorners(radius: 12)
        button.titleLabel?.font = Brand.Typography.subheader(size: 16)
        return button
    }()
    
    private let recommendationLabel: UILabel = {
        let label = UILabel()
        label.text = "Rekomendasi Untukmu"
        label.font = Brand.Typography.subheader(size: 18)
        return label
    }()
    
    lazy var recommendationsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 160, height: 240)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(ProductCardView.self, forCellWithReuseIdentifier: ProductCardView.identifier)
        return cv
    }()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(shopButton)
        addSubview(recommendationLabel)
        addSubview(recommendationsCollectionView)
        
        iconView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        shopButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(48)
        }
        
        recommendationLabel.snp.makeConstraints { make in
            make.top.equalTo(shopButton.snp.bottom).offset(60)
            make.leading.equalToSuperview().offset(20)
        }
        
        recommendationsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendationLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250)
        }
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CartViewController())
}
