import UIKit
import SnapKit

final class ProductDetailViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let productId: UUID
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = Brand.secondary
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.header(size: 24)
        label.numberOfLines = 0
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 20)
        label.textColor = Brand.primary
        return label
    }()
    
    private let weightLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let stockLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 14).withWeight(.bold)
        label.textColor = Brand.accent
        return label
    }()
    
    private let descriptionHeader: UILabel = {
        let label = UILabel()
        label.text = "Description"
        label.font = Brand.Typography.subheader(size: 18)
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 16)
        label.numberOfLines = 0
        label.textColor = .label
        return label
    }()
    
    private let stepper = InteractiveStepper()
    
    private let addToCartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Add to Cart", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Brand.Typography.subheader(size: 18)
        button.roundCorners(radius: 12)
        return button
    }()
    
    private let recommendationTitle: UILabel = {
        let label = UILabel()
        label.text = "Recommended for You"
        label.font = Brand.Typography.subheader(size: 18)
        return label
    }()
    
    private let recommendationCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 140, height: 200)
        layout.minimumInteritemSpacing = 12
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(ProductCardView.self, forCellWithReuseIdentifier: ProductCardView.identifier)
        return cv
    }()
    
    private let viewCartButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("View Cart", for: .normal)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Brand.Typography.body(size: 14).withWeight(.bold)
        button.roundCorners(radius: 20)
        button.isHidden = true
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
        loadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Product Details"
        
        view.addSubview(scrollView)
        view.addSubview(viewCartButton)
        scrollView.addSubview(contentView)
        
        [imageView, nameLabel, priceLabel, weightLabel, stockLabel, 
         descriptionHeader, descriptionLabel, stepper, addToCartButton, 
         recommendationTitle, recommendationCollectionView].forEach { contentView.addSubview($0) }
        
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
            make.top.equalTo(imageView.bottomAnchor).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.bottomAnchor).offset(8)
            make.leading.equalToSuperview().inset(20)
        }
        
        weightLabel.snp.makeConstraints { make in
            make.centerY.equalTo(priceLabel)
            make.trailing.equalToSuperview().inset(20)
        }
        
        stockLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.bottomAnchor).offset(8)
            make.leading.equalToSuperview().inset(20)
        }
        
        stepper.snp.makeConstraints { make in
            make.top.equalTo(stockLabel.bottomAnchor).offset(20)
            make.leading.equalToSuperview().inset(20)
            make.width.equalTo(120)
            make.height.equalTo(40)
        }
        
        addToCartButton.snp.makeConstraints { make in
            make.centerY.equalTo(stepper)
            make.leading.equalTo(stepper.snp.trailing).offset(12)
            make.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        descriptionHeader.snp.makeConstraints { make in
            make.top.equalTo(stepper.bottomAnchor).offset(30)
            make.leading.equalToSuperview().inset(20)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionHeader.bottomAnchor).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        recommendationTitle.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.bottomAnchor).offset(40)
            make.leading.equalToSuperview().inset(20)
        }
        
        recommendationCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendationTitle.bottomAnchor).offset(12)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(210)
            make.bottom.equalToSuperview().offset(-40)
        }
        
        viewCartButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
            make.width.equalTo(120)
            make.height.equalTo(40)
        }
        
        addToCartButton.addTarget(self, action: #selector(didTapAddToCart), for: .touchUpInside)
        viewCartButton.addTarget(self, action: #selector(didTapViewCart), for: .touchUpInside)
    }
    
    private func loadData() {
        // Simulated data for demo
        nameLabel.text = "Premium Indomie Goreng"
        priceLabel.text = "Rp 3.500"
        weightLabel.text = "85g"
        stockLabel.text = "Stock: 42 left"
        descriptionLabel.text = "Indomie Mi Goreng is an instant noodles product line made under the Indomie brand by the Indofood company. It is a type of Mi goreng instant noodle. Indomie Mi Goreng is the most popular Indomie noodle flavor."
    }
    
    @objc private func didTapAddToCart() {
        viewCartButton.isHidden = false
        // Logic to add item to CartManager
    }
    
    @objc private func didTapViewCart() {
        coordinator?.showReviewOrder()
    }
}
