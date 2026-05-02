import UIKit
import Kingfisher
import Hero
import SnapKit
import SkeletonView

final class ProductCardView: UICollectionViewCell {
    static let identifier = "ProductCardView"
    
    private var product: Product?
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Brand.secondary
        iv.roundCorners(radius: 12)
        iv.isSkeletonable = true
        iv.skeletonCornerRadius = 12
        return iv
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 13).withWeight(.semibold)
        label.textColor = Brand.Text.primary
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        label.isSkeletonable = true
        label.linesCornerRadius = 4
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.price()
        label.textColor = Brand.Text.primary
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.isSkeletonable = true
        label.linesCornerRadius = 4
        return label
    }()

    private let originalPriceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.caption().withWeight(.regular)
        label.textColor = .systemGray
        label.isHidden = true
        return label
    }()
    
    private let discountBadge: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 10).withWeight(.bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.roundCorners(radius: 4)
        label.isHidden = true
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.unitLabel()
        label.textColor = Brand.Text.secondary
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let scarcityLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 10).withWeight(.bold)
        label.textColor = .white
        label.backgroundColor = Brand.accent
        label.textAlignment = .center
        label.roundCorners(radius: 4)
        label.isHidden = true
        return label
    }()
    
    private let priceStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 2
        stack.alignment = .leading
        stack.isSkeletonable = true
        return stack
    }()

    private let amountStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .center
        return stack
    }()
    
    private let stepper = InteractiveStepper()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.kf.cancelDownloadTask()
        imageView.image = nil
        nameLabel.text = nil
        priceLabel.text = nil
        unitLabel.text = nil
        scarcityLabel.isHidden = true
        stepper.setValue(0)
        stopLoading()
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.isSkeletonable = true
        
        // Add shadow to the cell layer (not contentView)
        self.backgroundColor = .clear
        self.layer.masksToBounds = false
        self.isSkeletonable = true
        self.applyCardShadow()
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceStack)
        
        priceStack.addArrangedSubview(originalPriceLabel)
        priceStack.addArrangedSubview(amountStack)
        amountStack.addArrangedSubview(priceLabel)
        amountStack.addArrangedSubview(unitLabel)
        
        contentView.addSubview(discountBadge)
        contentView.addSubview(scarcityLabel)
        contentView.addSubview(stepper)
        
        stepper.delegate = self
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(imageView.snp.width)
        }

        discountBadge.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.top).offset(8)
            make.trailing.equalTo(imageView.snp.trailing).offset(-8)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(45)
        }
        
        scarcityLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.top).offset(8)
            make.leading.equalTo(imageView.snp.leading).offset(8)
            make.height.equalTo(18)
            make.width.greaterThanOrEqualTo(60)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(10)
        }
        
        priceStack.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(10)
            make.trailing.lessThanOrEqualToSuperview().offset(-10)
        }
        
        stepper.snp.makeConstraints { make in
          make.centerX.equalToSuperview() // Centered horizontally
          make.bottom.equalToSuperview().inset(10) // Fixed to bottom
          make.width.equalTo(100)
          make.height.equalTo(32)
          // This ensures the stepper doesn't overlap the price if the text is long
          make.top.greaterThanOrEqualTo(priceStack.snp.bottom).offset(8)
        }
    }
    
    func startLoading() {
        contentView.showAnimatedGradientSkeleton()
    }
    
    func stopLoading() {
        contentView.hideSkeleton()
    }
    
    func configure(with product: Product) {
        stopLoading()
        self.product = product
        nameLabel.text = product.name
        
        let firstVariant = product.variants?.first
        let currentPrice = firstVariant?.priceOverride ?? product.basePrice
        priceLabel.text = currentPrice.formattedIDR
        
        if let override = firstVariant?.priceOverride, override < product.basePrice {
            originalPriceLabel.isHidden = false
            let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: product.basePrice.formattedIDR)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle, value: 2, range: NSMakeRange(0, attributeString.length))
            originalPriceLabel.attributedText = attributeString
            
            discountBadge.isHidden = false
            let discountPercent = Int((1.0 - (override / product.basePrice)) * 100)
            discountBadge.text = "\(discountPercent)% OFF"
            discountBadge.backgroundColor = .systemRed
        } else if product.tags?.contains("Flash Sale") == true {
            originalPriceLabel.isHidden = true
            discountBadge.isHidden = false
            discountBadge.text = "FLASH ⚡️"
            discountBadge.backgroundColor = Brand.accent
        } else {
            originalPriceLabel.isHidden = true
            discountBadge.isHidden = true
        }
        
        imageView.hero.id = "image_\(product.id.uuidString)"
        nameLabel.hero.id = "title_\(product.id.uuidString)"
        
        let weight = product.weightLabel ?? product.unitOfMeasure
        unitLabel.text = weight != nil ? "/ \(weight!)" : ""
        
        if let firstVariant = product.variants?.first {
            let stock = firstVariant.qtyOnHand
            if stock > 0 && stock < 5 {
                scarcityLabel.text = "Sisa \(stock)"
                scarcityLabel.isHidden = false
            } else {
                scarcityLabel.isHidden = true
            }
            // Sync with cart state
            let currentQty = CartManager.shared.quantity(for: firstVariant.id)
            stepper.setValue(currentQty)
        } else {
            scarcityLabel.isHidden = true
            stepper.setValue(0)
        }
        
        if let imageUrlString = product.images?.first, let url = URL(string: imageUrlString) {
            imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo", withConfiguration: UIImage.SymbolConfiguration(pointSize: 40))) { [weak self] result in
                if case .failure = result {
                    self?.setPlaceholder()
                }
            }
        } else {
            setPlaceholder()
        }
    }
    
    private func setPlaceholder() {
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray4
        imageView.contentMode = .center
    }
}

extension ProductCardView: InteractiveStepperDelegate {
    func stepper(_ stepper: InteractiveStepper, didUpdateValue value: Int) {
        guard let product = product,
              let firstVariant = product.variants?.first else { return }

        // 1. Convert Int price to Double for CartManager
        let price = Double(firstVariant.priceOverride ?? product.basePrice)

        // 2. Call the Manager (This triggers saveAndNotify() inside CartManager)
        CartManager.shared.setQuantity(
            variantId: firstVariant.id,
            quantity: value,
            name: product.name,
            price: price
        )

        // 3. Optional: Add Haptic Feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
}

#Preview {
   ProductCardView()
}
