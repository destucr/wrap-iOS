import UIKit
import SnapKit
import Kingfisher

class ProductDetailViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let productId: UUID
    private var product: Product?
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .secondarySystemBackground
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.header(size: 28)
        label.numberOfLines = 0
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.header(size: 22)
        label.textColor = Brand.primary
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body()
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let addToCartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add to Cart", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.roundCorners(radius: 16)
        button.titleLabel?.font = Brand.Typography.subheader()
        return button
    }()
    
    init(productId: UUID) {
        self.productId = productId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchProductDetail()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.largeTitleDisplayMode = .never
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        [imageView, nameLabel, priceLabel, descriptionLabel, addToCartButton].forEach {
            contentView.addSubview($0)
        }
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(350)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        addToCartButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(32)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        addToCartButton.addTarget(self, action: #selector(handleAddToCart), for: .touchUpInside)
    }
    
    @objc private func handleAddToCart() {
        guard let product = product, let variant = product.variants?.first else { return }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        CartManager.shared.add(
            variantId: variant.id,
            name: product.name,
            price: variant.priceOverride ?? product.basePrice
        )
        
        let originalTitle = addToCartButton.title(for: .normal)
        addToCartButton.setTitle("Added to Cart!", for: .normal)
        addToCartButton.backgroundColor = .systemGray2
        addToCartButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.addToCartButton.setTitle(originalTitle, for: .normal)
            self?.addToCartButton.backgroundColor = Brand.primary
            self?.addToCartButton.isEnabled = true
        }
    }
    
    private func fetchProductDetail() {
        Task {
            do {
                let fetchedProduct: Product = try await NetworkManager.shared.request(endpoint: "/catalog/products/\(productId.uuidString.lowercased())")
                self.product = fetchedProduct
                self.updateUI(with: fetchedProduct)
            } catch {
                print("Error fetching details: \(error)")
            }
        }
    }
    
    private func updateUI(with product: Product) {
        nameLabel.text = product.name
        priceLabel.text = "Rp \(Int(product.basePrice))"
        descriptionLabel.text = product.description
        
        if let imageUrl = product.images?.first, let url = URL(string: imageUrl) {
            imageView.kf.setImage(with: url)
        }
    }
}

// MARK: - Visual Documentation
#Preview {
    let dummyId = UUID()
    let vc = ProductDetailViewController(productId: dummyId)
    return UINavigationController(rootViewController: vc)
}
