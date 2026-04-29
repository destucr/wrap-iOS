import UIKit
import Kingfisher
import Hero
import SnapKit

final class ProductCardView: UICollectionViewCell {
    static let identifier = "ProductCardView"
    
    private var product: Product?
    
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Brand.secondary
        iv.roundCorners(radius: 12)
        return iv
    }()

    let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.productName()
        label.textColor = Brand.Text.primary
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.price()
        label.textColor = Brand.primary
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
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
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        
        // Add shadow to the cell layer (not contentView)
        self.backgroundColor = .clear
        self.layer.masksToBounds = false
        self.applyCardShadow()
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceStack)
        priceStack.addArrangedSubview(priceLabel)
        priceStack.addArrangedSubview(unitLabel)
        contentView.addSubview(scarcityLabel)
        contentView.addSubview(stepper)
        
        stepper.delegate = self
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(imageView.snp.width)
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
    
    func configure(with product: Product) {
        self.product = product
        nameLabel.text = product.name
        priceLabel.text = product.basePrice.formattedIDR
        
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
