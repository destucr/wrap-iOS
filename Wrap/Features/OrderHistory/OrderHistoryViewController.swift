import UIKit
import SnapKit
import SkeletonView

class OrderCell: UITableViewCell {
    static let identifier = "OrderCell"
    
    private let orderIdLabel = UILabel()
    private let statusLabel = UILabel()
    private let amountLabel = UILabel()
    private let dateLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.isSkeletonable = true
        orderIdLabel.font = .systemFont(ofSize: 16, weight: .bold)
        orderIdLabel.isSkeletonable = true
        orderIdLabel.linesCornerRadius = 4
        
        statusLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        statusLabel.isSkeletonable = true
        statusLabel.linesCornerRadius = 4
        
        amountLabel.font = .systemFont(ofSize: 16, weight: .medium)
        amountLabel.textAlignment = .right
        amountLabel.isSkeletonable = true
        amountLabel.linesCornerRadius = 4
        
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .secondaryLabel
        dateLabel.isSkeletonable = true
        dateLabel.linesCornerRadius = 4
        
        [orderIdLabel, statusLabel, amountLabel, dateLabel].forEach { contentView.addSubview($0) }
        
        orderIdLabel.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(16)
            make.width.greaterThanOrEqualTo(100)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(orderIdLabel.snp.bottom).offset(4)
            make.leading.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(16)
            make.width.greaterThanOrEqualTo(120)
        }
        
        amountLabel.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(16)
            make.width.greaterThanOrEqualTo(80)
        }
        
        statusLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(dateLabel)
            make.width.greaterThanOrEqualTo(60)
        }
    }
    
    func startLoading() {
        contentView.showAnimatedGradientSkeleton()
    }
    
    func stopLoading() {
        contentView.hideSkeleton()
    }
    
    func configure(with order: Order) {
        stopLoading()
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
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
    }
}

class OrderHistoryViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var orders: [Order] = []
    private var isLoading = false
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchOrders()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        fetchOrders(showLoading: false)
    }
    
    private func setupUI() {
        title = "Order History"
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.refreshControl = refreshControl
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        
        tableView.register(OrderCell.self, forCellReuseIdentifier: OrderCell.identifier)
        
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
    }

    @objc private func handleRefresh() {
        fetchOrders(showLoading: false)
    }
    
    private func fetchOrders(showLoading: Bool = true) {
        if showLoading {
            self.isLoading = true
            self.tableView.reloadData()
        }
        Task {
            do {
                let fetchedOrders = try await UserService.shared.fetchOrderHistory()
                self.isLoading = false
                refreshControl.endRefreshing()
                self.orders = fetchedOrders.sorted(by: { $0.createdAt > $1.createdAt })
                self.tableView.reloadData()
            } catch {
                self.isLoading = false
                refreshControl.endRefreshing()
                print("Failed to fetch orders: \(error)")
                self.tableView.reloadData()
            }
        }
    }
}

extension OrderHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isLoading ? 8 : orders.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OrderCell.identifier, for: indexPath) as! OrderCell
        if isLoading {
            cell.startLoading()
        } else {
            cell.configure(with: orders[indexPath.row])
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isLoading else { return }
        tableView.deselectRow(at: indexPath, animated: true)
        let order = orders[indexPath.row]
        coordinator?.showOrderDetail(orderId: order.id)
    }
}
