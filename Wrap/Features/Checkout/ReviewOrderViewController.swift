import UIKit
import SnapKit

final class ReviewOrderViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var recommendations: [Product] = []
    private var cartItems: [CartItem] = []
    private var previewResponse: CheckoutPreviewResponse?
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = .clear
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        return tv
    }()
    
    private let emptyStateView = EmptyCartView()
    
    // Sticky Bottom Bar
    private let bottomBar = UIView()
    private let totalPaymentLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Pembayaran"
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
        button.setTitle("Bayar Sekarang", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = Brand.Typography.subheader(size: 16)
        button.roundCorners(radius: 12)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupObservers()
        fetchRecommendations()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateUIState()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
    }
    
    @objc private func cartDidUpdate() {
        updateUIState()
    }
    
    private func setupUI() {
        view.backgroundColor = Brand.secondary
        title = "Review Order"

        // 1. Order of addSubview matters for shadow visibility
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(bottomBar) // Add last so shadow is on top

        tableView.delegate = self
        tableView.dataSource = self
        // ... identifiers ...

        // 2. FIXED: Bottom Bar Styling & Constraints
        bottomBar.backgroundColor = .white
        bottomBar.applyShadow() // Ensure this applies a TOP shadow

        bottomBar.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview()
            // Remove height: equalTo(100). Let content decide.
        }

        bottomBar.addSubview(totalPaymentLabel)
        bottomBar.addSubview(finalTotalLabel)
        bottomBar.addSubview(payButton)

        // 1. Register your custom cell classes
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.identifier)
        tableView.register(ReviewItemCell.self, forCellReuseIdentifier: ReviewItemCell.identifier)
        tableView.register(PricingCell.self, forCellReuseIdentifier: PricingCell.identifier)

        // 2. Set delegate and datasource AFTER registration
        tableView.delegate = self
        tableView.dataSource = self

        totalPaymentLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.equalToSuperview().offset(20)
        }

        finalTotalLabel.snp.makeConstraints { make in
            make.top.equalTo(totalPaymentLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(20)
            // FIXED: Anchor to Safe Area Bottom to handle Home Indicator padding
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-16)
        }

        payButton.snp.makeConstraints { make in
            // FIXED: Centering on the whole text block or the final label
            make.centerY.equalTo(finalTotalLabel.snp.top).offset(0)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalTo(140) // Industry standard width
            make.height.equalTo(50)  // Industry standard "Thumb" height
        }

        // 3. FIXED: TableView Constraint
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomBar.snp.top)
        }

        // 4. FIXED: Empty State should cover everything
        emptyStateView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
    }
    
    private func fetchRecommendations() {
        Task {
            do {
                let products: [Product] = try await NetworkManager.shared.request(endpoint: "/catalog/products")
                self.recommendations = Array(products.prefix(10))
                self.emptyStateView.recommendationsCollectionView.reloadData()
            } catch {
                print("Failed to fetch recommendations: \(error)")
            }
        }
    }
    
    private func updateUIState() {
        self.cartItems = CartManager.shared.items
        let isEmpty = cartItems.isEmpty
        
        tableView.isHidden = isEmpty
        bottomBar.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        if isEmpty {
            navigationItem.title = ""
            previewResponse = nil
        } else {
            navigationItem.title = "Review Order"
            fetchPreview()
        }
        
        // Update tab badge
        if let cartTab = tabBarController?.tabBar.items?[1] {
            let count = CartManager.shared.totalCount
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }

    private func fetchPreview() {
        Task {
            do {
                let response = try await CartManager.shared.previewCheckout()
                self.previewResponse = response
                self.tableView.reloadData()
                self.updateSummary()
                
                // Disable pay button if inventory is invalid
                self.payButton.isEnabled = response.isValid
                self.payButton.backgroundColor = response.isValid ? Brand.primary : .systemGray4
            } catch {
                print("Failed to fetch checkout preview: \(error)")
                // Fallback to local calculation if network fails
                self.tableView.reloadData()
                self.updateSummary()
            }
        }
    }
    
    private func updateSummary() {
        if let response = previewResponse {
            finalTotalLabel.text = response.total.formattedIDR
        } else {
            let subtotal = CartManager.shared.totalAmount
            let deliveryFee = 5000.0
            let serviceFee = 1000.0
            let total = subtotal + deliveryFee + serviceFee
            finalTotalLabel.text = total.formattedIDR
        }
    }
    
    @objc private func handleMulaiBelanja() {
        tabBarController?.selectedIndex = 0
    }
    
    @objc private func didTapPay() {
        Task {
            do {
                let address: [String: String] = [
                    "street": "Jl. Merdeka No. 12",
                    "floor_unit": "402",
                    "postal_code": "12345"
                ]
                let response = try await CartManager.shared.placeOrder(address: address)
                CartManager.shared.clear()
                coordinator?.showOrderSuccess(orderId: response.orderId.uuidString, paymentUrl: response.paymentUrl)
            } catch {
                print("Order placement failed: \(error)")
            }
        }
    }
}

// MARK: - UITableView Delegate & DataSource
extension ReviewOrderViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Address
        case 1: return cartItems.count // Items
        case 2: return 1 // Pricing
        default: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: AddressCell.identifier, for: indexPath) as! AddressCell
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: ReviewItemCell.identifier, for: indexPath) as! ReviewItemCell
            let item = cartItems[indexPath.row]
            let previewItem = previewResponse?.items.first(where: { $0.variantId == item.variantId })
            
            cell.configure(with: item, message: previewItem?.message)
            cell.onQuantityChange = { [weak self] newQty in
                CartManager.shared.setQuantity(variantId: item.variantId, quantity: newQty)
                self?.updateUIState()
            }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: PricingCell.identifier, for: indexPath) as! PricingCell
            if let response = previewResponse {
                cell.configure(with: response)
            } else {
                cell.configure(subtotal: CartManager.shared.totalAmount)
            }
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 { return "Ringkasan Pesanan" }
        return nil
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 1 {
            let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] (_, _, completion) in
                guard let self = self else { return }
                CartManager.shared.remove(variantId: self.cartItems[indexPath.row].variantId)
                completion(true)
            }
            deleteAction.image = UIImage(systemName: "trash")
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        return nil
    }
}

// MARK: - CollectionView (Recommendations)
extension ReviewOrderViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
        cell.configure(with: recommendations[indexPath.item])
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let product = recommendations[indexPath.item]
        coordinator?.showProductDetail(productId: product.id)
    }
}

extension ReviewOrderViewController: ProductCardDelegate {
    func productCard(_ cell: ProductCardView, didUpdateQuantity quantity: Int, for product: Product) {
        guard let firstVariant = product.variants?.first else { return }
        let price = firstVariant.priceOverride ?? product.basePrice
        if quantity > 0 && CartManager.shared.items.first(where: { $0.variantId == firstVariant.id }) == nil {
            CartManager.shared.add(variantId: firstVariant.id, name: product.name, price: price, quantity: quantity)
        } else {
            CartManager.shared.setQuantity(variantId: firstVariant.id, quantity: quantity)
        }
        updateUIState()
    }
}

// MARK: - Custom Cells
final class AddressCell: UITableViewCell {
    static let identifier = "AddressCell"
    private let container = UIView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(container)
        container.backgroundColor = .white
        container.roundCorners(radius: 12)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        nameLabel.text = "Destu"
        nameLabel.font = Brand.Typography.subheader(size: 16)
        addressLabel.text = "Jl. Merdeka No. 12, Floor 4, Unit 402"
        addressLabel.font = Brand.Typography.body(size: 14)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 2
        
        [nameLabel, addressLabel].forEach { container.addSubview($0) }
        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().offset(16)
        }
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview().inset(16)
        }
    }
}

final class ReviewItemCell: UITableViewCell {
    static let identifier = "ReviewItemCell"
    private let container = UIView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 11)
        label.textColor = .systemRed
        label.isHidden = true
        return label
    }()
    private let stepper = InteractiveStepper()
    var onQuantityChange: ((Int) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(container)
        container.backgroundColor = .white
        container.roundCorners(radius: 12)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }
        
        nameLabel.font = Brand.Typography.body(size: 14).withWeight(.bold)
        nameLabel.numberOfLines = 2
        priceLabel.font = Brand.Typography.body(size: 14)
        stepper.delegate = self
        
        [nameLabel, priceLabel, warningLabel, stepper].forEach { container.addSubview($0) }
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalTo(stepper.snp.leading).offset(-12)
        }
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().offset(12)
        }
        warningLabel.snp.makeConstraints { make in
            make.top.equalTo(priceLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(12)
            make.bottom.equalToSuperview().offset(-12)
        }
        stepper.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().offset(-12)
            make.width.equalTo(100)
            make.height.equalTo(32)
        }
    }
    
    func configure(with item: CartItem, message: String? = nil) {
        nameLabel.text = item.name
        priceLabel.text = item.price.formattedIDR
        stepper.setValue(item.quantity)
        
        if let message = message {
            warningLabel.text = message
            warningLabel.isHidden = false
            container.layer.borderWidth = 1
            container.layer.borderColor = UIColor.systemRed.withAlphaComponent(0.3).cgColor
        } else {
            warningLabel.isHidden = true
            container.layer.borderWidth = 0
        }
    }
}

extension ReviewItemCell: InteractiveStepperDelegate {
    func stepper(_ stepper: InteractiveStepper, didUpdateValue value: Int) {
        onQuantityChange?(value)
    }
}

final class PricingCell: UITableViewCell {
    static let identifier = "PricingCell"
    private let container = UIView()
    private let stack = UIStackView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        contentView.addSubview(container)
        container.backgroundColor = .white
        container.roundCorners(radius: 12)
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16))
        }
        
        stack.axis = .vertical
        stack.spacing = 12
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(16)
        }
    }
    
    func configure(subtotal: Double) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(createRow(label: "Total Harga Barang", value: subtotal.formattedIDR))
        stack.addArrangedSubview(createRow(label: "Voucher", value: "- Rp0"))
    }
    
    func configure(with response: CheckoutPreviewResponse) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(createRow(label: "Total Harga Barang", value: response.subtotal.formattedIDR))
        stack.addArrangedSubview(createRow(label: "Delivery Fee", value: response.deliveryFee.formattedIDR))
        stack.addArrangedSubview(createRow(label: "Service Fee", value: response.serviceFee.formattedIDR))
        stack.addArrangedSubview(createRow(label: "Voucher", value: "- Rp0"))
    }
    
    private func createRow(label: String, value: String, isTotal: Bool = false) -> UIStackView {
        let l = UILabel()
        l.text = label
        l.font = isTotal ? Brand.Typography.subheader(size: 16) : Brand.Typography.body(size: 14)

        let v = UILabel()
        v.text = value
        v.font = isTotal ? Brand.Typography.subheader(size: 16) : Brand.Typography.body(size: 14)
        // Optional: v.textColor = isTotal ? Brand.Colours.emerald : .label

        let stack = UIStackView(arrangedSubviews: [l, v])
        stack.axis = .horizontal
        stack.distribution = .equalSpacing
        return stack
    }

}
