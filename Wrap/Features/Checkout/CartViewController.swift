import UIKit
import SnapKit

class CartItemCell: UITableViewCell {
    static let identifier = "CartItemCell"
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()
    
    private let quantityLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let priceLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .semibold)
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
        contentView.addSubview(nameLabel)
        contentView.addSubview(quantityLabel)
        contentView.addSubview(priceLabel)
        
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
    private let tableView = UITableView()
    
    private let checkoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Checkout", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
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
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(totalLabel)
        view.addSubview(checkoutButton)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(CartItemCell.self, forCellReuseIdentifier: CartItemCell.identifier)
        
        checkoutButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.bottom.equalTo(checkoutButton.snp.top).offset(-20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(totalLabel.snp.top).offset(-10)
        }
        
        checkoutButton.addTarget(self, action: #selector(handleCheckout), for: .touchUpInside)
    }
    
    private func updateTotal() {
        totalLabel.text = "Total: Rp \(Int(CartManager.shared.totalAmount))"
        checkoutButton.isEnabled = !CartManager.shared.items.isEmpty
        checkoutButton.alpha = CartManager.shared.items.isEmpty ? 0.5 : 1.0
    }
    
    @objc private func handleCheckout() {
        CartManager.shared.syncWithBackend { [weak self] success in
            if success {
                self?.coordinator?.showCheckoutPreview()
            } else {
                // Show alert error
                let alert = UIAlertController(title: "Error", message: "Could not sync your cart. Please try again.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
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
