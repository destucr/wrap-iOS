import UIKit
import SnapKit
import Kingfisher

class ProductCell: UITableViewCell {
    static let identifier = "ProductCell"
    
    private let containerView = UIView()
    
    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 12
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader()
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body()
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
        containerView.roundCorners(radius: 16)
        // containerView.applyShadow() // Optional: iOS HIG often prefers subtle outlines or background contrast
        
        containerView.addSubview(productImageView)
        
        let stackView = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        containerView.addSubview(stackView)
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        productImageView.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview().inset(12)
            make.size.equalTo(80)
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(productImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    func configure(with product: Product) {
        nameLabel.text = product.name
        priceLabel.text = "Rp \(Int(product.basePrice))"
        
        if let imageUrlString = product.images?.first, let url = URL(string: imageUrlString) {
            productImageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            productImageView.image = UIImage(systemName: "photo")
        }
    }
}

class CatalogViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var products: [Product] = []
    private var category: Category?
    
    init(category: Category? = nil) {
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
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateCartBadge), name: .cartUpdated, object: nil)
    }
    
    @objc private func updateCartBadge() {
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
        
        tableView.delegate = self
        tableView.dataSource = self
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
                var endpoint = "/catalog/products"
                if let categoryId = category?.id {
                    endpoint += "?category_id=\(categoryId.uuidString.lowercased())"
                }
                
                let fetchedProducts: [Product] = try await NetworkManager.shared.request(endpoint: endpoint)
                activityIndicator.stopAnimating()
                self.products = fetchedProducts
                self.tableView.reloadData()
            } catch {
                activityIndicator.stopAnimating()
                print("Failed to fetch catalog: \(error)")
            }
        }
    }
}

extension CatalogViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return products.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.identifier, for: indexPath) as? ProductCell else {
            return UITableViewCell()
        }
        cell.configure(with: products[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = products[indexPath.row]
        coordinator?.showProductDetail(productId: product.id)
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CatalogViewController())
}
