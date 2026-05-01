import UIKit
import SnapKit
import SafariServices
import AuthenticationServices
import Combine

@MainActor
final class ReviewOrderViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var webAuthSession: ASWebAuthenticationSession?
    private var recommendations: [Product] = []
    private var cartItems: [CartItemDTO] = []
    private var selectedAccount: LinkedAccount?
    private var linkedAccounts: [LinkedAccount] = []
    private var previewResponse: CheckoutPreviewResponse?
    private var previewTask: Task<Void, Never>?
    private var previewState: ViewState<CheckoutPreviewResponse> = .idle
    private var cancellables = Set<AnyCancellable>()
    
    // Diffable Data Source Types
    nonisolated private enum Section: Int, CaseIterable, Hashable, Sendable {
        case address
        case items
        case payment
        case pricing
        case recommendations
    }
    
    nonisolated private enum RowItem: Hashable, Sendable {
        case address
        case cartItem(CartItemDTO, message: String?, isLoading: Bool)
        case voucher
        case paymentMethod(LinkedAccount?)
        case pricing(CheckoutPreviewResponse?, Double, isLoading: Bool)
        case recommendation(Product)
    }
    
    private typealias DataSource = UITableViewDiffableDataSource<Section, RowItem>
    private typealias Snapshot = NSDiffableDataSourceSnapshot<Section, RowItem>
    
    private var dataSource: DataSource!
    
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
        label.font = .systemFont(ofSize: 18, weight: .thin)
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
        configureDataSource()
        setupObservers()
        fetchRecommendations()
        fetchLinkedAccounts()
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
        title = "Tinjau Pesanan"
        
        [tableView, bottomPaymentBar, emptyStateView].forEach { view.addSubview($0) }
        
        bottomPaymentBar.backgroundColor = .white
        [finalAmountLabel, totalLabel, payButton, bottomSeparator].forEach { bottomPaymentBar.addSubview($0) }
        bottomSeparator.backgroundColor = Brand.secondary
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(bottomPaymentBar.snp.top)
        }
        
        bottomPaymentBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(100)
        }
        
        bottomSeparator.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.equalToSuperview().offset(20)
        }
        
        finalAmountLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(2)
            make.leading.equalTo(totalLabel)
        }
        
        payButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-20)
            make.centerY.equalToSuperview()
            make.width.equalTo(160)
            make.height.equalTo(52)
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.edges.equalTo(tableView)
        }
        
        tableView.register(AddressCell.self, forCellReuseIdentifier: AddressCell.identifier)
        tableView.register(ReviewItemCell.self, forCellReuseIdentifier: ReviewItemCell.identifier)
        tableView.register(VoucherCell.self, forCellReuseIdentifier: VoucherCell.identifier)
        tableView.register(PaymentMethodCell.self, forCellReuseIdentifier: PaymentMethodCell.identifier)
        tableView.register(PricingCell.self, forCellReuseIdentifier: PricingCell.identifier)
        
        payButton.addTarget(self, action: #selector(didTapPay), for: .touchUpInside)
    }
    
    private func configureDataSource() {
        dataSource = DataSource(tableView: tableView) { [weak self] (tableView: UITableView, indexPath: IndexPath, item: RowItem) -> UITableViewCell? in
            guard let self = self else { return nil }
            
            switch item {
            case .address:
                return tableView.dequeueReusableCell(withIdentifier: AddressCell.identifier, for: indexPath)
                
            case .cartItem(let cartItem, let message, let isLoading):
                let cell = tableView.dequeueReusableCell(withIdentifier: ReviewItemCell.identifier, for: indexPath) as! ReviewItemCell
                if isLoading {
                    cell.startLoading()
                } else {
                    cell.configure(with: cartItem, message: message)
                    cell.onQuantityChange = { newQty in
                        CartManager.shared.setQuantity(variantId: cartItem.variantId, quantity: newQty, name: cartItem.name, price: cartItem.price)
                    }
                }
                return cell
                
            case .voucher:
                return tableView.dequeueReusableCell(withIdentifier: VoucherCell.identifier, for: indexPath)
                
            case .paymentMethod(let account):
                let cell = tableView.dequeueReusableCell(withIdentifier: PaymentMethodCell.identifier, for: indexPath) as! PaymentMethodCell
                if let account = account {
                    cell.configure(with: account)
                } else {
                    cell.configureDefault()
                }
                return cell
                
            case .pricing(let response, let subtotal, let isLoading):
                let cell = tableView.dequeueReusableCell(withIdentifier: PricingCell.identifier, for: indexPath) as! PricingCell
                if isLoading {
                    cell.startLoading()
                } else if let response = response {
                    cell.configure(with: response)
                } else {
                    cell.configure(subtotal: subtotal)
                }
                return cell
                
            case .recommendation:
                return UITableViewCell()
            }
        }
        dataSource.defaultRowAnimation = .fade
    }
    
    private func updateUIState() {
        let items = CartManager.shared.items
        self.cartItems = items.map { CartItemDTO(variantId: $0.variantId, name: $0.name, price: $0.price, quantity: $0.quantity) }
        
        let isEmpty = cartItems.isEmpty
        emptyStateView.isHidden = !isEmpty
        tableView.isHidden = isEmpty
        bottomPaymentBar.isHidden = isEmpty
        
        if !isEmpty {
            fetchPreview()
            applySnapshot()
        }
    }
    
    private func applySnapshot() {
        var snapshot = Snapshot()
        snapshot.appendSections([.address, .items, .payment, .pricing])
        
        snapshot.appendItems([.address], toSection: .address)
        
        let isLoading = previewState.isLoading
        let itemRows = cartItems.map { item -> RowItem in
            let message = previewResponse?.items.first(where: { $0.variantId == item.variantId })?.message
            return .cartItem(item, message: message, isLoading: isLoading)
        }
        snapshot.appendItems(itemRows, toSection: .items)
        
        snapshot.appendItems([.voucher, .paymentMethod(selectedAccount)], toSection: .payment)
        
        snapshot.appendItems([.pricing(previewResponse, CartManager.shared.totalAmount, isLoading: isLoading)], toSection: .pricing)
        
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    private func fetchRecommendations() {
        Task {
            do {
                self.recommendations = try await CatalogService.shared.fetchProducts()
                applySnapshot()
            } catch {
                print("Recommendations failed: \(error)")
            }
        }
    }
    
    private func fetchLinkedAccounts() {
        Task {
            do {
                let accounts = try await PaymentService.shared.fetchLinkedAccounts()
                self.linkedAccounts = accounts
                if let ovo = linkedAccounts.first(where: { $0.channelCode == "ID_OVO" }) {
                    self.selectedAccount = ovo
                } else {
                    self.selectedAccount = linkedAccounts.first
                }
                applySnapshot()
            } catch {
                print("Failed to fetch linked accounts: \(error)")
            }
        }
    }

    private func fetchPreview() {
        previewTask?.cancel()
        previewState = .loading
        applySnapshot()
        updateSummary()
        
        previewTask = Task {
            do {
                let response = try await CartManager.shared.previewCheckout()
                guard !Task.isCancelled else { return }
                self.previewResponse = response
                self.previewState = .success(response)
                self.applySnapshot()
                self.updateSummary()
                self.payButton.isEnabled = response.isValid
                self.payButton.backgroundColor = response.isValid ? Brand.primary : .systemGray4
            } catch {
                if Task.isCancelled { return }
                print("Preview failed: \(error)")
                self.previewState = .error(error.localizedDescription)
                self.applySnapshot()
                self.updateSummary()
                self.payButton.isEnabled = false
                self.payButton.backgroundColor = .systemGray4
            }
        }
    }
    
    private func updateSummary() {
        switch previewState {
        case .idle:
            finalAmountLabel.text = "Rp--"
        case .loading:
            finalAmountLabel.text = "Memuat..."
        case .success(let response):
            finalAmountLabel.text = response.total.formattedIDR
        case .error:
            let total = CartManager.shared.totalAmount + 6000.0
            finalAmountLabel.text = total.formattedIDR
        }
    }
    
    @objc private func handleMulaiBelanja() {
        tabBarController?.selectedIndex = 0
    }
    
    private func resetPayButton() {
        payButton.isEnabled = true
        payButton.alpha = 1.0
        payButton.setTitle("Bayar Sekarang", for: .normal)
    }
    
    @objc private func didTapPay() {
        payButton.isEnabled = false
        payButton.alpha = 0.5
        payButton.setTitle("Memproses...", for: .normal)
        
        Task {
            do {
                let address: [String: String] = [
                    "street": "Jl. Merdeka No. 12",
                    "floor_unit": "402",
                    "postal_code": "12345"
                ]
                let response = try await CartManager.shared.placeOrder(address: address, linkedAccountId: selectedAccount?.id)
                CartManager.shared.clear()
                
                if response.paymentUrl == "DIRECT_DEBIT_PAID" {
                    coordinator?.showOrderTracking(orderId: response.orderId.uuidString)
                } else if selectedAccount != nil, let url = URL(string: response.paymentUrl) {
                    let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "wrapapp") { [weak self] callbackURL, error in
                        if let url = callbackURL, url.absoluteString.contains("success") {
                            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
                            let orderId = components?.queryItems?.first(where: { $0.name == "order_id" })?.value ?? response.orderId.uuidString
                            self?.coordinator?.showOrderSuccess(orderId: orderId, paymentUrl: "DIRECT_DEBIT_PAID")
                        } else {
                            self?.resetPayButton()
                            if error == nil && callbackURL == nil {
                            } else if let url = callbackURL {
                                self?.coordinator?.showOrderHistory()
                            }
                        }
                    }
                    session.presentationContextProvider = self
                    session.prefersEphemeralWebBrowserSession = true
                    self.webAuthSession = session
                    session.start()
                } else {
                    coordinator?.showOrderSuccess(orderId: response.orderId.uuidString, paymentUrl: response.paymentUrl)
                }
            } catch {
                print("Order placement failed: \(error)")
                self.resetPayButton()
                let alert = UIAlertController(title: "Gagal", message: "Gagal membuat pesanan. Silakan coba lagi.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }

    private func showPaymentMethodPicker() {
        let alert = UIAlertController(title: "Metode Pembayaran", message: "Pilih e-wallet untuk pembayaran instan", preferredStyle: .actionSheet)
        for account in linkedAccounts {
            let channel = account.channelCode.replacingOccurrences(of: "ID_", with: "")
            alert.addAction(UIAlertAction(title: "\(channel) (\(account.accountDetails))", style: .default) { _ in
                self.selectedAccount = account
                self.applySnapshot()
            })
        }
        alert.addAction(UIAlertAction(title: "+ Hubungkan Akun Baru", style: .default) { _ in
            let vc = PaymentMethodsViewController()
            self.navigationController?.pushViewController(vc, animated: true)
        })
        alert.addAction(UIAlertAction(title: "Transfer Bank / Manual", style: .default) { _ in
            self.selectedAccount = nil
            self.applySnapshot()
        })
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UITableView Delegate
extension ReviewOrderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard let item = dataSource.itemIdentifier(for: indexPath) else { return }
        
        switch item {
        case .paymentMethod:
            showPaymentMethodPicker()
        default:
            break
        }
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding
extension ReviewOrderViewController: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window ?? UIWindow()
    }
}

// MARK: - SFSafariViewControllerDelegate
extension ReviewOrderViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        coordinator?.showOrderHistory()
    }
}

// MARK: - Redesigned Cells

final class AddressCell: UITableViewCell {
    static let identifier = "AddressCell"
    private let container = UIView()
    private let iconView = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let editIcon = UIImageView(image: UIImage(systemName: "chevron.right"))
    
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
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 4, right: 16))
        }
        
        iconView.tintColor = Brand.primary
        titleLabel.text = "Alamat Pengiriman"
        titleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        titleLabel.textColor = Brand.Text.secondary
        
        subtitleLabel.text = "Jl. Merdeka No. 12, Jakarta Pusat"
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        subtitleLabel.textColor = Brand.Text.primary
        
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        labelStack.axis = .vertical
        labelStack.spacing = 2
        
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
    
    private let thumbnailSkeleton = SkeletonView()
    private let nameSkeleton = SkeletonView()
    private let priceSkeleton = SkeletonView()
    
    var onQuantityChange: ((Int) -> Void)?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupSkeleton()
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
        
        priceLabel.font = .systemFont(ofSize: 14, weight: .thin)
        priceLabel.textColor = Brand.Text.primary
        
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
    
    private func setupSkeleton() {
        [thumbnailSkeleton, nameSkeleton, priceSkeleton].forEach { container.addSubview($0) }
        thumbnailSkeleton.snp.makeConstraints { make in
            make.edges.equalTo(thumbnail)
        }
        nameSkeleton.snp.makeConstraints { make in
            make.top.equalTo(nameLabel)
            make.leading.equalTo(nameLabel)
            make.width.equalTo(120)
            make.height.equalTo(16)
        }
        priceSkeleton.snp.makeConstraints { make in
            make.top.equalTo(priceLabel)
            make.leading.equalTo(priceLabel)
            make.width.equalTo(60)
            make.height.equalTo(14)
        }
        [thumbnailSkeleton, nameSkeleton, priceSkeleton].forEach { $0.isHidden = true }
    }
    
    func startLoading() {
        [thumbnailSkeleton, nameSkeleton, priceSkeleton].forEach {
            $0.isHidden = false
            $0.start()
        }
        [thumbnail, nameLabel, priceLabel, stepper].forEach { $0.isHidden = true }
    }
    
    func stopLoading() {
        [thumbnailSkeleton, nameSkeleton, priceSkeleton].forEach {
            $0.stop()
            $0.isHidden = true
        }
        [thumbnail, nameLabel, priceLabel, stepper].forEach { $0.isHidden = false }
    }
    
    func configure(with item: CartItemDTO, message: String? = nil) {
        stopLoading()
        nameLabel.text = item.name
        priceLabel.text = item.price.formattedIDR
        stepper.value = item.quantity
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
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
    
    func configure(with account: LinkedAccount) {
        title.text = "Metode Pembayaran"
        let channel = account.channelCode.replacingOccurrences(of: "ID_", with: "")
        methodLabel.text = "\(channel) - \(account.accountDetails)"
    }
    
    func configureDefault() {
        title.text = "Metode Pembayaran"
        methodLabel.text = "Transfer Bank"
    }
}

final class PricingCell: UITableViewCell {
    static let identifier = "PricingCell"
    private let container = UIView()
    private let stack = UIStackView()
    
    // Dynamic Shimmers
    private let deliverySkeleton = SkeletonView()
    private let totalSkeleton = SkeletonView()
    
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
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 20, right: 16))
        }
        
        stack.axis = .vertical
        stack.spacing = 0
        container.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(8) }
    }
    
    func startLoading() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        stack.addArrangedSubview(createRow(label: "Ringkasan Pesanan", value: CartManager.shared.totalAmount.formattedIDR))
        stack.addArrangedSubview(createDivider())
        stack.addArrangedSubview(createShimmerRow(label: "Biaya Pengiriman"))
        stack.addArrangedSubview(createDivider())
        stack.addArrangedSubview(createRow(label: "Biaya Layanan", value: (1000.0).formattedIDR))
        stack.addArrangedSubview(createDivider())
        stack.addArrangedSubview(createShimmerRow(label: "Total Pembayaran", isTotal: true))
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
        l.font = isTotal ? .systemFont(ofSize: 15, weight: .semibold) : .systemFont(ofSize: 14)
        
        let v = UILabel(); v.text = value
        v.font = isTotal ? .systemFont(ofSize: 15, weight: .thin) : .systemFont(ofSize: 14, weight: .thin)
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
    
    private func createShimmerRow(label: String, isTotal: Bool = false) -> UIView {
        let view = UIView()
        let l = UILabel(); l.text = label
        l.font = isTotal ? .systemFont(ofSize: 15, weight: .semibold) : .systemFont(ofSize: 14)
        
        let skeleton = SkeletonView()
        
        view.addSubview(l); view.addSubview(skeleton)
        l.snp.makeConstraints { make in 
            make.leading.equalToSuperview().offset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }
        skeleton.snp.makeConstraints { make in 
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalTo(l)
            make.width.equalTo(60)
            make.height.equalTo(14)
        }
        skeleton.start()
        return view
    }
    
    private func createDivider() -> UIView {
        let v = UIView(); v.backgroundColor = UIColor(red: 0.90, green: 0.90, blue: 0.92, alpha: 1.0)
        v.snp.makeConstraints { make in make.height.equalTo(1) }
        return v
    }
}
