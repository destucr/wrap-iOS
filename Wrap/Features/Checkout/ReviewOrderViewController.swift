import UIKit
import SnapKit

final class ReviewOrderViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var stepperToVariantMap: [InteractiveStepper: UUID] = [:]
    
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
    private let priceStack = UIStackView()
    
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
        updateSummary()
        setupObservers()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
    }
    
    @objc private func cartDidUpdate() {
        // Only reload if we are not currently dragging or if count changed
        loadItems()
        updateSummary()
    }
    
    private func setupUI() {
        view.backgroundColor = Brand.secondary
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
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
        
        // Pricing Card Setup
        pricingCard.backgroundColor = .white
        pricingCard.roundCorners(radius: 12)
        
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
            make.height.equalTo(100 + (UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0))
        }
        
        bottomBar.addSubview(totalPaymentLabel)
        bottomBar.addSubview(finalTotalLabel)
        bottomBar.addSubview(payButton)
        
        totalPaymentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
        }
        
        finalTotalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalPaymentLabel.snp.bottom).offset(2)
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
            make.top.equalTo(addressCard.snp.bottom).offset(24)
            make.leading.equalToSuperview().offset(16)
        }
        
        itemsStack.snp.makeConstraints { make in
            make.top.equalTo(itemsHeader.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        pricingCard.snp.makeConstraints { make in
            make.top.equalTo(itemsStack.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-20)
        }
        
        payButton.addTarget(self, action: #selector(didTapPay), for: .touchUpInside)
    }
    
    private func loadItems() {
        itemsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stepperToVariantMap.removeAll()
        
        let cartItems = CartManager.shared.items
        for item in cartItems {
            let itemView = UIView()
            itemView.backgroundColor = .white
            itemView.roundCorners(radius: 12)
            
            let name = UILabel()
            name.text = item.name
            name.font = Brand.Typography.body(size: 14).withWeight(.bold)
            
            let price = UILabel()
            price.text = String(format: "Rp %.0f", item.price)
            price.font = Brand.Typography.body(size: 14)
            
            let s = InteractiveStepper()
            s.setValue(item.quantity)
            s.delegate = self
            stepperToVariantMap[s] = item.variantId
            
            [name, price, s].forEach { itemView.addSubview($0) }
            
            name.snp.makeConstraints { make in
                make.top.leading.equalToSuperview().offset(12)
                make.trailing.equalTo(s.snp.leading).offset(-8)
            }
            price.snp.makeConstraints { make in
                make.top.equalTo(name.snp.bottom).offset(4)
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
    
    private func updateSummary() {
        priceStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let subtotal = CartManager.shared.totalAmount
        let deliveryFee = 5000.0
        let serviceFee = 1000.0
        let total = subtotal + deliveryFee + serviceFee
        
        priceStack.addArrangedSubview(createPricingRow(label: "Total Harga Barang", value: String(format: "Rp %.0f", subtotal)))
        priceStack.addArrangedSubview(createPricingRow(label: "Delivery Fee", value: String(format: "Rp %.0f", deliveryFee)))
        priceStack.addArrangedSubview(createPricingRow(label: "Service Fee", value: String(format: "Rp %.0f", serviceFee)))
        priceStack.addArrangedSubview(createPricingRow(label: "Voucher", value: "- Rp 0"))
        
        finalTotalLabel.text = String(format: "Rp %.0f", total)
    }
    
    @objc private func didTapPay() {
        // To be implemented with Xendit integration
        Task {
            do {
                let address: [String: String] = [
                    "street": "Jl. Merdeka No. 12",
                    "floor_unit": "402",
                    "postal_code": "12345"
                ]
                let response = try await CartManager.shared.placeOrder(address: address)
                coordinator?.showOrderSuccess(orderId: response.orderId.uuidString, paymentUrl: response.paymentUrl)
            } catch {
                print("Order placement failed: \(error)")
            }
        }
    }
}

extension ReviewOrderViewController: InteractiveStepperDelegate {
    func stepper(_ stepper: InteractiveStepper, didUpdateValue value: Int) {
        guard let variantId = stepperToVariantMap[stepper] else { return }
        
        CartManager.shared.setQuantity(variantId: variantId, quantity: value)
        
        if value <= 0 {
            // Re-load items to remove the view
            loadItems()
        }
        
        updateSummary()
    }
}
