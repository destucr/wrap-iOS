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
        label.text = "📍 Detecting location..."
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        return label
    }()
    
    private var detectedAddress: UserAddress?
    
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
        fetchLocation()
    }
    
    private func fetchLocation() {
        addressLabel.text = "📍 Detecting location..."
        Task {
            do {
                let address = try await LocationManager.shared.getCurrentAddress()
                self.detectedAddress = address
                self.addressLabel.text = "Deliver to:\n\(address.street), \(address.city)"
            } catch {
                self.addressLabel.text = "Could not detect location. Tap to try again."
                print("Location error: \(error)")
            }
        }
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleAddressTap))
        addressLabel.isUserInteractionEnabled = true
        addressLabel.addGestureRecognizer(tap)
    }
    
    @objc private func handleAddressTap() {
        fetchLocation()
    }
    
    private func loadData() {
        let itemTexts = CartManager.shared.items.map { "- \($0.name) x \($0.quantity)" }
        itemsLabel.text = itemTexts.joined(separator: "\n")
        totalLabel.text = "Total to Pay: Rp \(Int(CartManager.shared.totalAmount))"
    }
    
    @objc private func handlePlaceOrder() {
        guard let address = detectedAddress else {
            let alert = UIAlertController(title: "Location Required", message: "Please wait until we detect your delivery address.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        placeOrderButton.isEnabled = false
        placeOrderButton.setTitle("", for: .normal)
        activityIndicator.startAnimating()
        
        Task {
            do {
                let payload = ["street": address.street, "city": address.city]
                let response = try await CartManager.shared.placeOrder(address: payload)
                activityIndicator.stopAnimating()
                placeOrderButton.isEnabled = true
                placeOrderButton.setTitle("Place Order", for: .normal)
                
                CartManager.shared.clear()
                coordinator?.showOrderSuccess(orderId: response.orderId.uuidString, paymentUrl: response.paymentUrl)
            } catch let error as NetworkError {
                activityIndicator.stopAnimating()
                placeOrderButton.isEnabled = true
                placeOrderButton.setTitle("Place Order", for: .normal)
                
                if case .conflict = error {
                    let alert = UIAlertController(title: "Out of Stock", message: "Some items in your cart just went out of stock. Please update your cart.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    present(alert, animated: true)
                } else {
                    print("Failed to place order: \(error)")
                }
            } catch {
                activityIndicator.stopAnimating()
                placeOrderButton.isEnabled = true
                placeOrderButton.setTitle("Place Order", for: .normal)
                print("Failed to place order: \(error)")
            }
        }
    }
}

// MARK: - Visual Documentation
#Preview {
    UINavigationController(rootViewController: CheckoutPreviewViewController())
}
