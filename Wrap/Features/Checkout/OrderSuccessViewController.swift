import UIKit
import SnapKit
import SafariServices

class OrderSuccessViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let orderId: String
    private let paymentUrl: String
    
    private let successImageView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = .systemGreen
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Order Placed!"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let orderIdLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let instructionsLabel: UILabel = {
        let label = UILabel()
        label.text = "Your items are reserved for 15 minutes. Please complete the payment to finalize your order."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let payNowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Pay Now", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        return button
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back to Home", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        return button
    }()
    
    init(orderId: String, paymentUrl: String) {
        self.orderId = orderId
        self.paymentUrl = paymentUrl
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        let isPaid = paymentUrl == "DIRECT_DEBIT_PAID"
        
        if isPaid {
            titleLabel.text = "Payment Successful!"
            instructionsLabel.text = "We've received your payment. Your order is now being processed."
            payNowButton.isHidden = true
            doneButton.setTitle("Track Order", for: .normal)
            
            // Auto-transition to tracking after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                self.coordinator?.showOrderTracking(orderId: self.orderId)
            }
        } else {
            titleLabel.text = "Order Placed!"
            instructionsLabel.text = "Your items are reserved for 15 minutes. Please complete the payment to finalize your order."
            payNowButton.isHidden = false
            doneButton.setTitle("Back to Home", for: .normal)
        }
        
        [successImageView, titleLabel, orderIdLabel, instructionsLabel, payNowButton, doneButton].forEach {
            view.addSubview($0)
        }
        
        successImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(successImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        orderIdLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        orderIdLabel.text = "Order ID: \(orderId)"
        
        instructionsLabel.snp.makeConstraints { make in
            make.top.equalTo(orderIdLabel.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        payNowButton.snp.makeConstraints { make in
            make.top.equalTo(instructionsLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(isPaid ? 0 : 56)
        }
        
        doneButton.snp.makeConstraints { make in
            make.top.equalTo(payNowButton.snp.bottom).offset(isPaid ? 0 : 20)
            make.centerX.equalToSuperview()
        }
        
        payNowButton.addTarget(self, action: #selector(handlePayNow), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
    }
    
    @objc private func handlePayNow() {
        guard let url = URL(string: paymentUrl) else { return }
        let safariVC = SFSafariViewController(url: url)
        present(safariVC, animated: true)
    }
    
    @objc private func handleDone() {
        if paymentUrl == "DIRECT_DEBIT_PAID" {
            coordinator?.showOrderTracking(orderId: orderId)
        } else {
            coordinator?.showCatalog()
        }
    }
}

// MARK: - Visual Documentation
#Preview {
    OrderSuccessViewController(orderId: "ORD-123", paymentUrl: "https://example.com")
}
