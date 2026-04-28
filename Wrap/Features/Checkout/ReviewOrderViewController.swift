import UIKit
import SnapKit

final class ReviewOrderViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // Identity Section
    private let addressCard = UIView()
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Destu"
        label.font = Brand.Typography.subheader(size: 16)
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Jl. Merdeka No. 12, Floor 4, Unit 402"
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()
    
    // Order List
    private let itemsHeader: UILabel = {
        let label = UILabel()
        label.text = "Order Summary"
        label.font = Brand.Typography.subheader(size: 18)
        return label
    }()
    
    private let itemsStack = UIStackView()
    
    // Pricing Breakdown
    private let pricingCard = UIView()
    private func createPricingRow(label: String, value: String, isTotal: Bool = false) -> UIStackView {
        let l = UILabel()
        l.text = label
        l.font = isTotal ? Brand.Typography.subheader(size: 18) : Brand.Typography.body(size: 14)
        
        let v = UILabel()
        v.text = value
        v.font = isTotal ? Brand.Typography.subheader(size: 18) : Brand.Typography.body(size: 14)
        v.textColor = isTotal ? Brand.primary : .label
        
        let stack = UIStackView(arrangedSubviews: [l, v])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }
    
    // Sticky Bottom Bar
    private let bottomBar = UIView()
    private let totalPaymentLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Payment"
        label.font = Brand.Typography.body(size: 12)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let finalTotalLabel: UILabel = {
        let label = UILabel()
        label.text = "Rp 35.000"
        label.font = Brand.Typography.header(size: 20)
        label.textColor = .black
        return label
    }()
    
    private let payButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pay Now", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Brand.Typography.subheader(size: 16)
        button.roundCorners(radius: 12)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadItems()
    }
    
    private func setupUI() {
        view.backgroundColor = Brand.secondary // Neutral background for cards
        title = "Review Order"
        
        view.addSubview(scrollView)
        view.addSubview(bottomBar)
        scrollView.addSubview(contentView)
        
        [addressCard, itemsHeader, itemsStack, pricingCard].forEach { contentView.addSubview($0) }
        
        // Address Card Setup
        addressCard.backgroundColor = .white
        addressCard.roundCorners(radius: 12)
        addressCard.addSubview(nameLabel)
        addressCard.addSubview(addressLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.bottomAnchor).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        
        // Pricing Card Setup
        pricingCard.backgroundColor = .white
        pricingCard.roundCorners(radius: 12)
        let priceStack = UIStackView(arrangedSubviews: [
            createPricingRow(label: "Total Harga Barang", value: "Rp 30.000"),
            createPricingRow(label: "Delivery Fee", value: "Rp 5.000"),
            createPricingRow(label: "Service Fee", value: "Rp 1.000"),
            createPricingRow(label: "Voucher", value: "- Rp 0", isTotal: false)
        ])
        priceStack.axis = .vertical
        priceStack.spacing = 12
        pricingCard.addSubview(priceStack)
        priceStack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
        
        // Layout Constraints
        bottomBar.backgroundColor = .white
        bottomBar.applyShadow()
        bottomBar.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            make.height.equalTo(100)
        }
        
        bottomBar.addSubview(totalPaymentLabel)
        bottomBar.addSubview(finalTotalLabel)
        bottomBar.addSubview(payButton)
        
        totalPaymentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        finalTotalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalPaymentLabel.bottomAnchor).offset(2)
            make.leading.equalToSuperview().offset(20)
        }
        
        payButton.snp.makeConstraints { make in
            make.centerY.equalTo(finalTotalLabel)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalTo(120)
            make.height.equalTo(44)
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        addressCard.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        itemsHeader.snp.makeConstraints { make in
            make.top.equalTo(addressCard.bottomAnchor).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        itemsStack.snp.makeConstraints { make in
            make.top.equalTo(itemsHeader.bottomAnchor).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        pricingCard.snp.makeConstraints { make in
            make.top.equalTo(itemsStack.bottomAnchor).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
    }
    
    private func loadItems() {
        // Simulated items
        for i in 1...2 {
            let itemView = UIView()
            itemView.backgroundColor = .white
            itemView.roundCorners(radius: 12)
            
            let name = UILabel()
            name.text = "Product \(i)"
            name.font = Brand.Typography.body(size: 14).withWeight(.bold)
            
            let price = UILabel()
            price.text = "Rp 15.000"
            price.font = Brand.Typography.body(size: 14)
            
            let s = InteractiveStepper()
            s.setValue(1)
            
            [name, price, s].forEach { itemView.addSubview($0) }
            
            name.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().offset(12)
            }
            price.snp.makeConstraints { make in
                make.top.equalTo(name.bottomAnchor).offset(4)
                make.leading.equalToSuperview().offset(12)
                make.bottom.equalToSuperview().offset(-12)
            }
            s.snp.makeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-12)
                make.width.equalTo(100)
                make.height.equalTo(32)
            }
            
            itemsStack.addArrangedSubview(itemView)
        }
        itemsStack.axis = .vertical
        itemsStack.spacing = 8
    }
}
