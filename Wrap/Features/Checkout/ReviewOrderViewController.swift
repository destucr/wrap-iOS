import UIKit
import SnapKit

@MainActor
final class ReviewOrderViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var recommendations: [Product] = []
    private var cartItems: [CartItem] = []
    private var previewResponse: CheckoutPreviewResponse?
    private var previewTask: Task<Void, Never>?
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        tv.backgroundColor = Brand.secondary
        tv.separatorStyle = .none
        tv.showsVerticalScrollIndicator = false
        tv.sectionHeaderHeight = 8
        tv.sectionFooterHeight = .leastNormalMagnitude
        return tv
    }()
    
    private let emptyStateView = EmptyCartView()
    
    // Floating Bottom Payment Bar
    private let bottomPaymentBar = UIView()
    private let bottomSeparator = UIView()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.text = "Total Pembayaran"
        label.font = .systemFont(ofSize: 13, weight: .regular)
        label.textColor = Brand.Text.secondary
        return label
    }()
    
    private let finalAmountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22, weight: .bold)
        label.textColor = Brand.Text.primary
        return label
    }()
    
    private let payButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Bayar Sekarang", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.roundCorners(radius: 14)
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
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Brand.secondary
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            .font: UIFont.systemFont(ofSize: 34, weight: .bold),
            .foregroundColor: Brand.Text.primary
        ]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
    }

    override func viewWillDisappear(_ animated: Bool) {
         super.viewWillDisappear(animated)
         // This makes sure the header comes back when you
         // push a new screen or pop back to the previous one
         navigationController?.setNavigationBarHidden(false, animated: animated)
     }

    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
    }
    
    @objc private func cartDidUpdate() {
        updateUIState()
    }
    
    private func setupUI() {
        view.backgroundColor = Brand.secondary
        title = "Ringkasan Pesanan"
        navigationItem.backButtonDisplayMode = .minimal
        
        view.addSubview(tableView)
        view.addSubview(emptyStateView)
        view.addSubview(bottomPaymentBar)
        
        bottomPaymentBar.backgroundColor = .white
        bottomPaymentBar.addSubview(bottomSeparator)
        bottomPaymentBar.addSubview(totalLabel)
        bottomPaymentBar.addSubview(finalAmountLabel)
        bottomPaymentBar.addSubview(payButton)
        
        bottomSeparator.backgroundColor = UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1.0) // #E5E5EA
        
        // Shadow for bottom bar
        bottomPaymentBar.layer.shadowColor = UIColor.black.cgColor
        bottomPaymentBar.layer.shadowOffset = CGSize(width: 0, height: -3)
        bottomPaymentBar.layer.shadowRadius = 10
        bottomPaymentBar.layer.shadowOpacity = 0.05
        
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.identifier)
        tableView.register(ReviewItemCell.self, forCellReuseIdentifier: ReviewItemCell.identifier)
        tableView.register(VoucherCell.self, forCellReuseIdentifier: VoucherCell.identifier)
        tableView.register(PaymentMethodCell.self, forCellReuseIdentifier: PaymentMethodCell.identifier)
        tableView.register(PricingCell.self, forCellReuseIdentifier: PricingCell.identifier)
        
        tableView.delegate = self
        tableView.dataSource = self
        emptyStateView.recommendationsCollectionView.delegate = self
        emptyStateView.recommendationsCollectionView.dataSource = self

        bottomPaymentBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-80)
        }
        
        bottomSeparator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(20)
        }
        
        finalAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(20)
        }
        
        payButton.snp.makeConstraints { make in
            make.centerY.equalTo(bottomPaymentBar.snp.top).offset(40)
            make.trailing.equalToSuperview().offset(-20)
            make.width.equalTo(160)
            make.height.equalTo(52)
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.edges.equalToSuperview() // Fill the entire screen
        }

        // Ensure the tableView follows the same logic if it isn't already
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomPaymentBar.snp.top)
        }

        payButton.addTarget(self, action: #selector(didTapPay), for: .touchUpInside)
        emptyStateView.shopButton.addTarget(self, action: #selector(handleMulaiBelanja), for: .touchUpInside)
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

        navigationController?.setNavigationBarHidden(isEmpty, animated: true)

        tableView.isHidden = isEmpty
        bottomPaymentBar.isHidden = isEmpty
        emptyStateView.isHidden = !isEmpty
        
        previewResponse = nil
        tableView.reloadData()
        updateSummary()
        
        if isEmpty {
            navigationItem.title = ""
            view.setNeedsLayout()
        } else {
            navigationItem.title = "Ringkasan Pesanan"
            fetchPreview()
        }

        if let cartTab = tabBarController?.tabBar.items?[1] {
            let count = CartManager.shared.totalCount
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }

    private func fetchPreview() {
        previewTask?.cancel()
        previewTask = Task {
            do {
                let response = try await CartManager.shared.previewCheckout()
                guard !Task.isCancelled else { return }
                self.previewResponse = response
                self.tableView.reloadData()
                self.updateSummary()
                self.payButton.isEnabled = response.isValid
                self.payButton.backgroundColor = response.isValid ? Brand.primary : .systemGray4
            } catch {
                if Task.isCancelled { return }
                self.payButton.isEnabled = true
                self.payButton.backgroundColor = Brand.primary
            }
        }
    }
    
    private func updateSummary() {
        let total: Double
        if let response = previewResponse {
            total = response.total
        } else {
            total = CartManager.shared.totalAmount + 6000.0 // Local fallback: 5k delivery + 1k service
        }
        finalAmountLabel.text = total.formattedIDR
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
        return 4
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1 // Address
        case 1: return cartItems.count // Items
        case 2: return 2 // Voucher + Payment Method
        case 3: return 1 // Pricing Summary Card
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
                CartManager.shared.setQuantity(variantId: item.variantId, quantity: newQty, name: item.name, price: item.price)
            }
            return cell
        case 2:
            if indexPath.row == 0 {
                let cell = tableView.dequeueReusableCell(withIdentifier: VoucherCell.identifier, for: indexPath) as! VoucherCell
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodCell.identifier, for: indexPath) as! PaymentMethodCell
                return cell
            }
        case 3:
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
}

// MARK: - Recommendations
extension ReviewOrderViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return recommendations.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
        cell.configure(with: recommendations[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         let product = recommendations[indexPath.item]

         // 1. Show the navigation bar immediately so the Detail screen can use it
         navigationController?.setNavigationBarHidden(false, animated: true)

         // 2. Navigate
         coordinator?.showProductDetail(productId: product.id)
    }
}

// MARK: - Redesigned Cells

final class AddressCell: UITableViewCell {
    static let identifier = "AddressCell"
    private let container = UIView()
    private let iconView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
    private let labelStack = UIStackView()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()
    private let editIcon = UIImageView(image: UIImage(systemName: "pencil"))
    
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
        container.roundCorners()
        
        // Shadow: black 6% opacity, blur 6pt
        container.applyShadow(opacity: 0.06, radius: 6)
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
        }
        
        iconView.tintColor = Brand.primary
        iconView.contentMode = .scaleAspectFit
        
        nameLabel.text = "Destu"
        nameLabel.font = .systemFont(ofSize: 15, weight: .bold)
        
        addressLabel.text = "Jl. Merdeka No. 12, Floor 4, Unit 402"
        addressLabel.font = .systemFont(ofSize: 14)
        addressLabel.textColor = Brand.Text.secondary
        addressLabel.numberOfLines = 2
        
        labelStack.axis = .vertical
        labelStack.spacing = 2
        labelStack.addArrangedSubview(nameLabel)
        labelStack.addArrangedSubview(addressLabel)
        
        editIcon.tintColor = Brand.Text.secondary
        editIcon.contentMode = .scaleAspectFit
        
        [iconView, labelStack, editIcon].forEach { container.addSubview($0) }
        
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
            make.size.equalTo(24)
        }
        
        labelStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.top.bottom.equalToSuperview().inset(16)
            make.trailing.equalTo(editIcon.snp.leading).offset(-12)
        }
        
        editIcon.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
    }
}

final class ReviewItemCell: UITableViewCell {
    static let identifier = "ReviewItemCell"
    private let container = UIView()
    private let thumbnail = UIImageView()
    private let nameLabel = UILabel()
    private let priceLabel = UILabel()
    private let stepper = RedesignedStepper()
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
        container.roundCorners()
        container.applyShadow(opacity: 0.04, radius: 4, offset: CGSize(width: 0, height: 1))
        
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16))
        }
        
        thumbnail.backgroundColor = Brand.secondary
        thumbnail.layer.cornerRadius = 8
        thumbnail.clipsToBounds = true
        thumbnail.contentMode = .scaleAspectFill
        
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.numberOfLines = 2
        
        priceLabel.font = .systemFont(ofSize: 14, weight: .regular)
        priceLabel.textColor = Brand.Text.secondary
        
        [thumbnail, nameLabel, priceLabel, stepper].forEach { container.addSubview($0) }
        
        thumbnail.snp.makeConstraints { make in
            make.leading.top.equalToSuperview().offset(12)
            make.size.equalTo(56)
            make.bottom.lessThanOrEqualToSuperview().offset(-12)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(thumbnail)
            make.leading.equalTo(thumbnail.snp.trailing).offset(12)
            make.trailing.equalTo(stepper.snp.leading).offset(-12)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.equalTo(nameLabel)
        }
        
        stepper.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(36)
        }
        
        stepper.onValueChange = { [weak self] value in
            self?.onQuantityChange?(value)
        }
    }
    
    func configure(with item: CartItem, message: String? = nil) {
        nameLabel.text = item.name
        priceLabel.text = item.price.formattedIDR
        stepper.value = item.quantity
        // Note: thumbnail loading would go here if URL is available in CartItem
    }
}

final class RedesignedStepper: UIView {
    var value: Int = 0 { didSet { valueLabel.text = "\(value)" } }
    var onValueChange: ((Int) -> Void)?
    
    private let minusBtn = UIButton(type: .system)
    private let plusBtn = UIButton(type: .system)
    private let valueLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Brand.primary.withAlphaComponent(0.1)
        layer.cornerRadius = 18
        
        minusBtn.setImage(UIImage(systemName: "minus"), for: .normal)
        plusBtn.setImage(UIImage(systemName: "plus"), for: .normal)
        [minusBtn, plusBtn].forEach { $0.tintColor = Brand.primary }
        
        valueLabel.font = .systemFont(ofSize: 15, weight: .bold)
        valueLabel.textAlignment = .center
        
        let stack = UIStackView(arrangedSubviews: [minusBtn, valueLabel, plusBtn])
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview() }
        
        minusBtn.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)
        plusBtn.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError() }
    
    @objc private func didTapMinus() { if value > 0 { value -= 1; onValueChange?(value) } }
    @objc private func didTapPlus() { value += 1; onValueChange?(value) }
}

final class VoucherCell: UITableViewCell {
    static let identifier = "VoucherCell"
    private let container = UIView()
    private let icon = UIImageView(image: UIImage(systemName: "tag.fill"))
    private let title = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(container)
        container.backgroundColor = .white
        container.roundCorners()
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 4, right: 16))
            make.height.equalTo(52)
        }
        
        icon.tintColor = Brand.primary
        title.text = "Tambah Voucher"
        title.textColor = Brand.primary
        title.font = .systemFont(ofSize: 15, weight: .semibold)
        chevron.tintColor = .systemGray3
        
        [icon, title, chevron].forEach { container.addSubview($0) }
        icon.snp.makeConstraints { make in make.leading.equalToSuperview().offset(16); make.centerY.equalToSuperview(); make.size.equalTo(20) }
        title.snp.makeConstraints { make in make.leading.equalTo(icon.snp.trailing).offset(12); make.centerY.equalToSuperview() }
        chevron.snp.makeConstraints { make in make.trailing.equalToSuperview().offset(-16); make.centerY.equalToSuperview(); make.size.equalTo(14) }
    }
}

final class PaymentMethodCell: UITableViewCell {
    static let identifier = "PaymentMethodCell"
    private let container = UIView()
    private let icon = UIImageView(image: UIImage(systemName: "creditcard.fill"))
    private let title = UILabel()
    private let methodLabel = UILabel()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .clear
        contentView.addSubview(container)
        container.backgroundColor = .white
        container.roundCorners()
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 16, bottom: 8, right: 16))
            make.height.equalTo(52)
        }
        
        icon.tintColor = Brand.Text.secondary
        title.text = "Metode Pembayaran"
        title.font = .systemFont(ofSize: 15)
        methodLabel.text = "Transfer Bank"
        methodLabel.font = .systemFont(ofSize: 14)
        methodLabel.textColor = Brand.Text.secondary
        chevron.tintColor = .systemGray3
        
        [icon, title, methodLabel, chevron].forEach { container.addSubview($0) }
        icon.snp.makeConstraints { make in make.leading.equalToSuperview().offset(16); make.centerY.equalToSuperview(); make.size.equalTo(20) }
        title.snp.makeConstraints { make in make.leading.equalTo(icon.snp.trailing).offset(12); make.centerY.equalToSuperview() }
        methodLabel.snp.makeConstraints { make in make.trailing.equalTo(chevron.snp.leading).offset(-8); make.centerY.equalToSuperview() }
        chevron.snp.makeConstraints { make in make.trailing.equalToSuperview().offset(-16); make.centerY.equalToSuperview(); make.size.equalTo(14) }
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
        container.roundCorners()
        container.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16))
        }
        
        stack.axis = .vertical
        stack.spacing = 0
        container.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(8) }
    }
    
    func configure(subtotal: Double) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(createRow(label: "Ringkasan Pesanan", value: subtotal.formattedIDR))
        stack.addArrangedSubview(createDivider())
        stack.addArrangedSubview(createRow(label: "Biaya Pengiriman", value: "Dihitung saat checkout"))
        stack.addArrangedSubview(createDivider())
        stack.addArrangedSubview(createRow(label: "Biaya Layanan", value: (1000.0).formattedIDR))
        stack.addArrangedSubview(createDivider())
        stack.addArrangedSubview(createRow(label: "Total Pembayaran", value: (subtotal + 6000.0).formattedIDR, isTotal: true))
    }
    
    func configure(with response: CheckoutPreviewResponse) {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(createRow(label: "Ringkasan Pesanan", value: response.subtotal.formattedIDR))
        stack.addArrangedSubview(createDivider())
        
        let deliveryValue = response.deliveryFee == 0 ? "Gratis" : response.deliveryFee.formattedIDR
        let deliveryColor = response.deliveryFee == 0 ? Brand.primary : Brand.Text.primary
        stack.addArrangedSubview(createRow(label: "Biaya Pengiriman", value: deliveryValue, valueColor: deliveryColor))
        stack.addArrangedSubview(createDivider())
        
        stack.addArrangedSubview(createRow(label: "Biaya Layanan", value: response.serviceFee.formattedIDR))
        stack.addArrangedSubview(createDivider())
        
        stack.addArrangedSubview(createRow(label: "Total Pembayaran", value: response.total.formattedIDR, isTotal: true))
    }
    
    private func createRow(label: String, value: String, isTotal: Bool = false, valueColor: UIColor? = nil) -> UIView {
        let view = UIView()
        let l = UILabel(); l.text = label
        l.font = isTotal ? .systemFont(ofSize: 16, weight: .bold) : .systemFont(ofSize: 14)
        
        let v = UILabel(); v.text = value
        v.font = isTotal ? .systemFont(ofSize: 16, weight: .bold) : .systemFont(ofSize: 14)
        v.textColor = valueColor ?? Brand.Text.primary
        
        view.addSubview(l); view.addSubview(v)
        l.snp.makeConstraints { make in 
            make.leading.equalToSuperview().offset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }
        v.snp.makeConstraints { make in 
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(l)
        }
        return view
    }
    
    private func createDivider() -> UIView {
        let v = UIView(); v.backgroundColor = UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1.0)
        v.snp.makeConstraints { make in make.height.equalTo(1) }
        return v
    }
}
