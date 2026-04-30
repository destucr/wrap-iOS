import UIKit
import SnapKit

class OrderTrackingViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let orderId: String
    
    private let statusIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "box.truck.fill"))
        iv.tintColor = Brand.primary
        iv.contentMode = .scaleAspectFit
        return iv
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Payment Received!"
        label.font = Brand.Typography.header()
        label.textAlignment = .center
        return label
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "We're preparing your order. Your driver will be assigned shortly."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = Brand.Typography.body()
        label.textColor = .secondaryLabel
        return label
    }()
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Done", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.roundCorners()
        button.titleLabel?.font = Brand.Typography.subheader()
        return button
    }()
    
    init(orderId: String) {
        self.orderId = orderId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startPolling()
    }
    
    private func startPolling() {
        Task {
            // Polling every 5 seconds for simulation purposes
            for _ in 1...20 {
                do {
                    let order: Order = try await NetworkManager.shared.request(endpoint: "/user/orders/\(orderId)")
                    updateUI(with: order)
                    if order.deliveryStatus == .delivered {
                        break
                    }
                } catch {
                    print("Polling failed: \(error)")
                }
                try? await Task.sleep(nanoseconds: 5 * 1_000_000_000)
            }
        }
    }
    
    private func updateUI(with order: Order) {
        switch order.deliveryStatus {
        case .pending:
            statusLabel.text = "Order Received"
            messageLabel.text = "Waiting for driver assignment..."
        case .packing:
            statusLabel.text = "Packing Order"
            messageLabel.text = "The store is preparing your items."
            statusIcon.image = UIImage(systemName: "box.truck.fill")
        case .inTransit:
            statusLabel.text = "Driver on the Way!"
            messageLabel.text = "Your order is being delivered."
            statusIcon.image = UIImage(systemName: "figure.walk.motion")
        case .delivered:
            statusLabel.text = "Delivered! 🎉"
            messageLabel.text = "Hope you enjoy your purchase!"
            statusIcon.image = UIImage(systemName: "checkmark.seal.fill")
            statusIcon.tintColor = .systemGreen
        default:
            break
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        navigationItem.hidesBackButton = true
        
        [statusIcon, statusLabel, messageLabel, doneButton].forEach {
            view.addSubview($0)
        }
        
        statusIcon.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(60)
            make.centerX.equalToSuperview()
            make.size.equalTo(120)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.top.equalTo(statusIcon.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(statusLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        doneButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-40)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(56)
        }
        
        doneButton.addTarget(self, action: #selector(handleDone), for: .touchUpInside)
    }
    
    @objc private func handleDone() {
        coordinator?.showCatalog()
    }
}
