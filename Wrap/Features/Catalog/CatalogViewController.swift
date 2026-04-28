import UIKit
import SnapKit
import Kingfisher

class ProductCell: UITableViewCell {
    static let identifier = "ProductCell"
    
    private let productImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .regular)
        label.textColor = .systemGreen
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
        contentView.addSubview(productImageView)
        
        let stackView = UIStackView(arrangedSubviews: [nameLabel, priceLabel])
        stackView.axis = .vertical
        stackView.spacing = 4
        contentView.addSubview(stackView)
        
        productImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(60)
            make.top.bottom.equalToSuperview().inset(12)
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(productImageView.snp.trailing).offset(16)
            make.trailing.equalToSuperview().offset(-16)
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
    
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchCatalog()
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateCartButton), name: .cartUpdated, object: nil)
    }
    
    @objc private func updateCartButton() {
        let count = CartManager.shared.totalCount
        if count > 0 {
            navigationItem.rightBarButtonItem?.title = "Cart (\(count))"
            navigationItem.rightBarButtonItem?.image = nil
        } else {
            navigationItem.rightBarButtonItem?.title = nil
            navigationItem.rightBarButtonItem?.image = UIImage(systemName: "cart")
        }
    }
    
    private func setupUI() {
        title = "Wrap Catalog"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "cart"),
            style: .plain,
            target: self,
            action: #selector(handleShowCart)
        )
        updateCartButton()
        
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
    }
    
    @objc private func handleShowCart() {
        coordinator?.showCart()
    }
    
    private func fetchCatalog() {
        activityIndicator.startAnimating()
        NetworkManager.shared.request(endpoint: "/catalog/products") { [weak self] (result: Result<[Product], NetworkError>) in
            self?.activityIndicator.stopAnimating()
            switch result {
            case .success(let fetchedProducts):
                self?.products = fetchedProducts
                self?.tableView.reloadData()
            case .failure(let error):
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
        tableView.deselectRow(at: indexPath, animated: true)
        let product = products[indexPath.row]
        coordinator?.showProductDetail(productId: product.id)
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CatalogViewController())
}
