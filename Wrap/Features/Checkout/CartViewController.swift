import UIKit
import SnapKit

class CartItemCell: UITableViewCell {
    static let identifier = "CartItemCell"
    
    private let containerView = UIView()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 16)
        return label
    }()
    
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 16)
        label.textColor = Brand.primary
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.backgroundColor = .systemBackground
        containerView.roundCorners(radius: 12)
        
        containerView.addSubview(nameLabel)
        containerView.addSubview(quantityLabel)
        containerView.addSubview(priceLabel)
        
        containerView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        nameLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        quantityLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.bottom.equalToSuperview().inset(16)
        }
        
        priceLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
    }
    
    func configure(with item: CartItem) {
        nameLabel.text = item.name
        quantityLabel.text = "Quantity: \(item.quantity)"
        priceLabel.text = "Rp \(Int(item.price * Double(item.quantity)))"
    }
}

class CartViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .secondarySystemBackground
        return tv
    }()
    
    private let checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Proceed to Checkout", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.roundCorners(radius: 16)
        button.titleLabel?.font = Brand.Typography.subheader()
        return button
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.header(size: 22)
        label.textAlignment = .right
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        updateTotal()
    }
    
    private func setupUI() {
        title = "My Cart"
        navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .secondarySystemBackground
        
        view.addSubview(tableView)
        view.addSubview(totalLabel)
        view.addSubview(checkoutButton)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.identifier)
        
        checkoutButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-24)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(60)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.bottom.equalTo(checkoutButton.snp.top).offset(-24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(totalLabel.snp.top).offset(-12)
        }
        
        checkoutButton.addTarget(self, action: #selector(handleCheckout), for: .touchUpInside)
    }
    
    private func updateTotal() {
        totalLabel.text = "Total: Rp \(Int(CartManager.shared.totalAmount))"
        let isEmpty = CartManager.shared.items.isEmpty
        checkoutButton.isEnabled = !isEmpty
        checkoutButton.alpha = isEmpty ? 0.5 : 1.0
        
        // Update tab badge as well
        if let cartTab = tabBarController?.tabBar.items?[1] {
            let count = CartManager.shared.totalCount
            cartTab.badgeValue = count > 0 ? "\(count)" : nil
            cartTab.badgeColor = Brand.primary
        }
    }
    
    @objc private func handleCheckout() {
        Task {
            do {
                try await CartManager.shared.syncWithBackend()
                coordinator?.showCheckoutPreview()
            } catch {
                let alert = UIAlertController(title: "Error", message: "Could not sync your cart. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
}

extension CartViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return CartManager.shared.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: CartItemCell.identifier, for: indexPath) as? CartItemCell else {
            return UITableViewCell()
        }
        cell.configure(with: CartManager.shared.items[indexPath.row])
        return cell
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CartViewController())
}
