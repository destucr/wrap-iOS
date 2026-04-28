import UIKit
import SnapKit

class CheckoutPreviewViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.text = "Order Summary"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        return label
    }()
    
    private let itemsLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let totalLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .bold)
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Deliver to:\nJl. Jend. Sudirman No. 1, Purbalingga"
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let placeOrderButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Place Order", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    private func setupUI() {
        title = "Preview"
        view.backgroundColor = .systemBackground
        
        [summaryLabel, itemsLabel, totalLabel, addressLabel, placeOrderButton].forEach {
            view.addSubview($0)
        }
        view.addSubview(activityIndicator)
        
        summaryLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        itemsLabel.snp.makeConstraints { make in
            make.top.equalTo(summaryLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        totalLabel.snp.makeConstraints { make in
            make.top.equalTo(itemsLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(totalLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        placeOrderButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(placeOrderButton)
        }
        
        placeOrderButton.addTarget(self, action: #selector(handlePlaceOrder), for: .touchUpInside)
    }
    
    private func loadData() {
        let itemTexts = CartManager.shared.items.map { "- \($0.name) x \($0.quantity)" }
        itemsLabel.text = itemTexts.joined(separator: "\n")
        totalLabel.text = "Total to Pay: Rp \(Int(CartManager.shared.totalAmount))"
    }
    
    @objc private func handlePlaceOrder() {
        placeOrderButton.isEnabled = false
        placeOrderButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()
        
        CartManager.shared.placeOrder(address: ["full_address": "Jl. Jend. Sudirman No. 1", "postal_code": "53311"]) { [weak self] result in
            self?.activityIndicator.stopAnimating()
            self?.placeOrderButton.isEnabled = true
            self?.placeOrderButton.setTitle("Place Order", for: .normal)
            
            switch result {
            case .success(let response):
                CartManager.shared.clear()
                self?.coordinator?.showOrderSuccess(orderId: response["order_id"] ?? "", paymentUrl: response["payment_url"] ?? "")
            case .failure(let error):
                print("Failed to place order: \(error)")
            }
        }
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CheckoutPreviewViewController())
}
