import UIKit
import SnapKit
import Kingfisher
import Hero

@MainActor
final class ProductDetailViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let productId: UUID
    private var product: Product?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    // 1. Imagery
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Brand.secondary
        return iv
    }()
    
    // 2. Price Block
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.header(size: 28)
        label.textColor = Brand.primary
        return label
    }()
    
    // 3. Name
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 20)
        label.numberOfLines = 0
        return label
    }()
    
    // 4. Metadata Row
    private let metadataStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()
    
    private func createMetadataItem(label: String, value: String) -> UIView {
        let l = UILabel()
        l.text = "\(label): "
        l.font = Brand.Typography.body(size: 14)
        l.textColor = .secondaryLabel
        
        let v = UILabel()
        v.text = value
        v.font = Brand.Typography.body(size: 14).withWeight(.bold)
        
        let stack = UIStackView(arrangedSubviews: [l, v])
        stack.axis = .horizontal
        return stack
    }
    
    // 5. Description
    private let descriptionHeader: UILabel = {
        let label = UILabel()
        label.text = "Deskripsi Produk"
        label.font = Brand.Typography.subheader(size: 16)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 14)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    // 7. Sticky Bottom Bar
    private let bottomBar = UIView()
    private let stepper = InteractiveStepper()
    
    private let buyNowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Beli Sekarang", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Brand.Typography.subheader(size: 16)
        button.roundCorners(radius: 12)
        return button
    }()
    
    init(productId: UUID) {
        self.productId = productId
        super.init(nibName: nil, bundle: nil)
        self.hidesBottomBarWhenPushed = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchProductDetails()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
    }
    
    @objc private func cartDidUpdate() {
        updateStepperValue()
    }
    
    private func updateStepperValue() {
        guard let firstVariant = product?.variants?.first else { return }
        let currentQty = CartManager.shared.quantity(for: firstVariant.id)
        stepper.setValue(currentQty)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        view.addSubview(bottomBar)
        view.addSubview(activityIndicator)
        scrollView.addSubview(contentView)
        
        [imageView, priceLabel, nameLabel, metadataStack, 
         descriptionHeader, descriptionLabel].forEach { contentView.addSubview($0) }
        
        // Bottom Bar Setup
        bottomBar.backgroundColor = .systemBackground
        bottomBar.applyShadow()
        bottomBar.addSubview(stepper)
        bottomBar.addSubview(buyNowButton)
        
        stepper.delegate = self
        
        bottomBar.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(100 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
        }
        
        stepper.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        buyNowButton.snp.makeConstraints { make in
            make.centerY.equalTo(stepper)
            make.leading.equalTo(stepper.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(44)
        }
        
        // Scroll & Content
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(imageView.snp.width)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(20)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        metadataStack.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(12)
            make.leading.equalToSuperview().offset(20)
        }
        
        descriptionHeader.snp.makeConstraints { make in
            make.top.equalTo(metadataStack.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionHeader.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        buyNowButton.addTarget(self, action: #selector(didTapBuyNow), for: .touchUpInside)
    }
    
    private func fetchProductDetails() {
        activityIndicator.startAnimating()
        Task {
            do {
                let fetchedProduct: Product = try await NetworkManager.shared.request(endpoint: "/catalog/detail/\(productId.uuidString.lowercased())")
                self.product = fetchedProduct
                self.configureUI(with: fetchedProduct)
                activityIndicator.stopAnimating()
            } catch {
                activityIndicator.stopAnimating()
            }
        }
    }
    
    private func configureUI(with product: Product) {
        self.title = product.name 
        nameLabel.text = product.name
        priceLabel.text = product.basePrice.formattedIDR
        descriptionLabel.text = product.description ?? "Tidak ada deskripsi."

        imageView.hero.id = "image_\(product.id.uuidString)"
        nameLabel.hero.id = "title_\(product.id.uuidString)"
        
        self.hero.isEnabled = true
        
        // Add cascading animations to the rest of the elements
        priceLabel.hero.modifiers = [.fade, .translate(y: 20)]
        metadataStack.hero.modifiers = [.fade, .translate(y: 20)]
        descriptionHeader.hero.modifiers = [.fade, .translate(y: 20)]
        descriptionLabel.hero.modifiers = [.fade, .translate(y: 20)]
        bottomBar.hero.modifiers = [.fade, .translate(y: 50)]
        
        if let imageUrlString = product.images?.first, let url = URL(string: imageUrlString) {
            imageView.kf.setImage(with: url)
        }
        
        metadataStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let weight = product.weightLabel ?? product.unitOfMeasure ?? "-"
        metadataStack.addArrangedSubview(createMetadataItem(label: "Berat", value: weight))
        
        if let firstVariant = product.variants?.first {
            metadataStack.addArrangedSubview(createMetadataItem(label: "Stok", value: "\(firstVariant.qtyOnHand)"))
            updateStepperValue()
        }
        
        if let temp = product.temperatureControl, temp != "ambient" {
            metadataStack.addArrangedSubview(createMetadataItem(label: "Suhu", value: temp.capitalized))
        }
    }
    
    @objc private func didTapBuyNow() {
        guard let product = product, let firstVariant = product.variants?.first else { return }
        if CartManager.shared.quantity(for: firstVariant.id) == 0 {
            let price = firstVariant.priceOverride ?? product.basePrice
            CartManager.shared.add(variantId: firstVariant.id, name: product.name, price: price, quantity: 1)
        }
        coordinator?.showReviewOrder()
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
}

extension ProductDetailViewController: InteractiveStepperDelegate {
    func stepper(_ stepper: InteractiveStepper, didUpdateValue value: Int) {
        guard let product = product, let firstVariant = product.variants?.first else { return }
        let price = firstVariant.priceOverride ?? product.basePrice
        
        CartManager.shared.setQuantity(variantId: firstVariant.id, quantity: value, name: product.name, price: price)
    }
}

#Preview {
    ProductDetailViewController(productId: UUID())
}

