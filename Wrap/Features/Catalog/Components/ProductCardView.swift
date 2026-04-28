import UIKit
import Kingfisher

final class ProductCardView: UICollectionViewCell {
    static let identifier = "ProductCardView"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Brand.secondary
        iv.roundCorners(radius: 12)
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 16)
        label.textColor = .black
        label.numberOfLines = 2
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 14).withWeight(.bold)
        label.textColor = Brand.primary
        return label
    }()
    
    private let unitLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 12)
        label.textColor = .gray
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
        contentView.roundCorners(radius: 12)
        contentView.applyShadow()
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(priceLabel)
        contentView.addSubview(unitLabel)
        contentView.addSubview(scarcityLabel)
        contentView.addSubview(stepper)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        priceLabel.translatesAutoresizingMaskIntoConstraints = false
        unitLabel.translatesAutoresizingMaskIntoConstraints = false
        scarcityLabel.translatesAutoresizingMaskIntoConstraints = false
        stepper.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            
            scarcityLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 8),
            scarcityLabel.leadingAnchor.constraint(equalTo: imageView.leadingAnchor, constant: 8),
            scarcityLabel.heightAnchor.constraint(equalToConstant: 18),
            scarcityLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            
            priceLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            priceLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            
            unitLabel.centerYAnchor.constraint(equalTo: priceLabel.centerYAnchor),
            unitLabel.leadingAnchor.constraint(equalTo: priceLabel.trailingAnchor, constant: 4),
            
            stepper.topAnchor.constraint(equalTo: priceLabel.bottomAnchor, constant: 8),
            stepper.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            stepper.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            stepper.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            stepper.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
    
    func configure(with product: Product) {
        nameLabel.text = product.name
        priceLabel.text = String(format: "Rp %.0f", product.basePrice)
        
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
        } else {
            scarcityLabel.isHidden = true
        }
        
        if let imageUrlString = product.images?.first, let url = URL(string: imageUrlString) {
            imageView.kf.setImage(with: url, placeholder: UIImage(systemName: "photo"))
        } else {
            imageView.image = UIImage(systemName: "photo")
        }
    }
}
