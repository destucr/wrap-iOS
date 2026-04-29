import UIKit
import SnapKit

class OrderCell: UITableViewCell {
    static let identifier = "OrderCell"
    
    private let orderIdLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        return label
    }()
    
    private let amountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .right
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .secondaryLabel
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
        contentView.addSubview(orderIdLabel)
        contentView.addSubview(statusLabel)
        contentView.addSubview(amountLabel)
        contentView.addSubview(dateLabel)
        
        orderIdLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(orderIdLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
        }
        
        amountLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(16)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(dateLabel)
        }
    }
    
    func configure(with order: Order) {
        orderIdLabel.text = "Order #\(order.id.uuidString.prefix(8))"
        amountLabel.text = order.totalAmount.formattedIDR
        statusLabel.text = order.paymentStatus.rawValue
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        dateLabel.text = formatter.string(from: order.createdAt)
        
        switch order.paymentStatus {
        case .pending: statusLabel.textColor = .systemOrange
        case .paid: statusLabel.textColor = .systemGreen
        case .cancelled: statusLabel.textColor = .systemRed
        }
    }
}

class OrderHistoryViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var orders: [Order] = []
    private let tableView = UITableView()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchOrders()
    }
    
    private func setupUI() {
        title = "Order History"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderCell.self, forCellReuseIdentifier: OrderCell.identifier)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func fetchOrders() {
        activityIndicator.startAnimating()
        Task {
            do {
                let fetchedOrders: [Order] = try await NetworkManager.shared.request(endpoint: "/user/orders")
                activityIndicator.stopAnimating()
                self.orders = fetchedOrders.sorted(by: { $0.createdAt > $1.createdAt })
                self.tableView.reloadData()
            } catch {
                activityIndicator.stopAnimating()
                print("Failed to fetch orders: \(error)")
            }
        }
    }
}

extension OrderHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return orders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: OrderCell.identifier, for: indexPath) as? OrderCell else {
            return UITableViewCell()
        }
        cell.configure(with: orders[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let order = orders[indexPath.row]
        coordinator?.showOrderDetail(orderId: order.id)
    }
}
