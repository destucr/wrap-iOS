import UIKit
import SnapKit
import Kingfisher

class ProductDetailViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let productId: UUID
    private var productDetail: ProductDetail?
    
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
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.numberOfLines = 0
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .systemGreen
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let addToCartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add to Cart", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
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
            make.height.equalTo(300)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
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
            make.top.equalTo(descriptionLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
            make.bottom.equalToSuperview().offset(-30)
        }
        
        addToCartButton.addTarget(self, action: #selector(handleAddToCart), for: .touchUpInside)
    }
    
    @objc private func handleAddToCart() {
        guard let detail = productDetail, let variant = detail.variants.first else { return }
        
        // 1. Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        // 2. Local Add
        CartManager.shared.add(
            variantId: variant.id,
            name: detail.product.name,
            price: variant.priceOverride ?? detail.product.basePrice
        )
        
        // 3. UI Feedback (Temporary button state)
        let originalTitle = addToCartButton.title(for: .normal)
        addToCartButton.setTitle("Added!", for: .normal)
        addToCartButton.backgroundColor = .systemGray
        addToCartButton.isEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.addToCartButton.setTitle(originalTitle, for: .normal)
            self?.addToCartButton.backgroundColor = .systemBlue
            self?.addToCartButton.isEnabled = true
        }
    }
    
    private func fetchProductDetail() {
        NetworkManager.shared.request(endpoint: "/catalog/products/\(productId.uuidString.lowercased())") { [weak self] (result: Result<ProductDetail, NetworkError>) in
            switch result {
            case .success(let detail):
                self?.productDetail = detail
                self?.updateUI(with: detail)
            case .failure(let error):
                print("Error fetching details: \(error)")
            }
        }
    }
    
    private func updateUI(with detail: ProductDetail) {
        nameLabel.text = detail.product.name
        priceLabel.text = "Rp \(Int(detail.product.basePrice))"
        descriptionLabel.text = detail.product.description
        
        if let imageUrl = detail.product.images?.first, let url = URL(string: imageUrl) {
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
