import UIKit
import SnapKit

final class OrderDetailViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let orderId: UUID
    private var orderDetail: OrderDetailResponse?
    private var isLoading = false
    
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    
    init(orderId: UUID) {
        self.orderId = orderId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchOrderDetail()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        title = "Detail Pesanan"
        view.backgroundColor = .systemGroupedBackground
        
        view.addSubview(tableView)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(OrderItemDetailCell.self, forCellReuseIdentifier: OrderItemDetailCell.identifier)
        tableView.register(OrderRatingCell.self, forCellReuseIdentifier: OrderRatingCell.identifier)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func fetchOrderDetail() {
        isLoading = true
        tableView.reloadData()
        Task {
            do {
                let resp = try await UserService.shared.fetchOrderDetail(id: orderId)
                self.orderDetail = resp
                self.isLoading = false
                self.tableView.reloadData()
            } catch {
                self.isLoading = false
                print("Error fetching order detail: \(error)")
                self.tableView.reloadData()
            }
        }
    }
    
    private func submitRating(rating: Int, comment: String) {
        Task {
            do {
                try await UserService.shared.rateOrder(id: orderId, rating: rating, comment: comment)
                
                let alert = UIAlertController(title: "Berhasil", message: "Terima kasih atas ulasan Anda!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    self.fetchOrderDetail()
                })
                present(alert, animated: true)
            } catch {
                print("Error submitting rating: \(error)")
            }
        }
    }
}

extension OrderDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if isLoading { return 2 }
        guard orderDetail != nil else { return 0 }
        return 3 // Info, Items, Rating
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            if section == 0 { return 3 }
            return 2
        }
        guard let detail = orderDetail else { return 0 }
        if section == 0 { return 3 } // ID, Status, Total
        if section == 1 { return detail.items.count }
        if section == 2 { return (detail.paymentStatus == .paid) ? 1 : 0 }
        return 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isLoading {
            if section == 0 { return "Ringkasan" }
            return "Produk yang Dibeli"
        }
        if section == 0 { return "Ringkasan" }
        if section == 1 { return "Produk yang Dibeli" }
        if section == 2 && orderDetail?.paymentStatus == .paid { return "Beri Nilai Pesanan" }
        return nil
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLoading {
            if indexPath.section == 0 {
                let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
                cell.textLabel?.text = "---"
                cell.detailTextLabel?.text = "---"
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: OrderItemDetailCell.identifier, for: indexPath) as! OrderItemDetailCell
                cell.startLoading()
                return cell
            }
        }
        
        guard let detail = orderDetail else { return UITableViewCell() }
        
        if indexPath.section == 0 {
            let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
            cell.selectionStyle = .none
            if indexPath.row == 0 {
                cell.textLabel?.text = "ID Pesanan"
                cell.detailTextLabel?.text = "#\(detail.id.uuidString.prefix(8))"
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Status"
                cell.detailTextLabel?.text = detail.paymentStatus.rawValue
                cell.detailTextLabel?.textColor = detail.paymentStatus == .paid ? .systemGreen : .systemRed
            } else {
                cell.textLabel?.text = "Total Bayar"
                cell.detailTextLabel?.text = detail.totalAmount.formattedIDR
                cell.detailTextLabel?.font = .systemFont(ofSize: 16, weight: .bold)
            }
            return cell
        } else if indexPath.section == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderItemDetailCell.identifier, for: indexPath) as! OrderItemDetailCell
            cell.configure(with: detail.items[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: OrderRatingCell.identifier, for: indexPath) as! OrderRatingCell
            cell.configure(rating: detail.rating, comment: detail.ratingComment)
            cell.onRatingSubmit = { [weak self] rating, comment in
                self?.submitRating(rating: rating, comment: comment)
            }
            return cell
        }
    }
}

// MARK: - Supporting Views

final class OrderItemDetailCell: UITableViewCell {
    static let identifier = "OrderItemDetailCell"
    
    private let nameLabel = UILabel()
    private let variantLabel = UILabel()
    private let priceLabel = UILabel()
    
    private let nameSkeleton = SkeletonView()
    private let variantSkeleton = SkeletonView()
    private let priceSkeleton = SkeletonView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupSkeleton()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        selectionStyle = .none
        let stack = UIStackView(arrangedSubviews: [nameLabel, variantLabel, priceLabel])
        stack.axis = .vertical; stack.spacing = 4
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(12) }
        
        nameLabel.font = .systemFont(ofSize: 16, weight: .medium)
        variantLabel.font = .systemFont(ofSize: 12); variantLabel.textColor = .secondaryLabel
        priceLabel.font = .systemFont(ofSize: 14, weight: .semibold); priceLabel.textColor = Brand.primary
    }
    
    private func setupSkeleton() {
        [nameSkeleton, variantSkeleton, priceSkeleton].forEach { contentView.addSubview($0) }
        nameSkeleton.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(12)
            make.width.equalTo(150); make.height.equalTo(18)
        }
        variantSkeleton.snp.makeConstraints { make in
            make.top.equalTo(nameSkeleton.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(12)
            make.width.equalTo(100); make.height.equalTo(14)
        }
        priceSkeleton.snp.makeConstraints { make in
            make.top.equalTo(variantSkeleton.snp.bottom).offset(6)
            make.leading.equalToSuperview().inset(12)
            make.width.equalTo(80); make.height.equalTo(16)
            make.bottom.equalToSuperview().inset(12)
        }
        [nameSkeleton, variantSkeleton, priceSkeleton].forEach { $0.isHidden = true }
    }
    
    func startLoading() {
        [nameSkeleton, variantSkeleton, priceSkeleton].forEach { $0.isHidden = false; $0.start() }
        [nameLabel, variantLabel, priceLabel].forEach { $0.isHidden = true }
    }
    
    func stopLoading() {
        [nameSkeleton, variantSkeleton, priceSkeleton].forEach { $0.stop(); $0.isHidden = true }
        [nameLabel, variantLabel, priceLabel].forEach { $0.isHidden = false }
    }
    
    func configure(with item: OrderItem) {
        stopLoading()
        nameLabel.text = item.productName
        variantLabel.text = "\(item.variantName) x \(item.quantity)"
        priceLabel.text = (item.priceAtPurchase * Double(item.quantity)).formattedIDR
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopLoading()
    }
}

final class OrderRatingCell: UITableViewCell {
    static let identifier = "OrderRatingCell"
    var onRatingSubmit: ((Int, String) -> Void)?
    
    private var currentRating: Int = 0
    private let starStack = UIStackView()
    private let commentField = UITextField()
    private let submitButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        selectionStyle = .none
        starStack.axis = .horizontal; starStack.distribution = .fillEqually; starStack.spacing = 8
        for i in 1...5 {
            let btn = UIButton()
            btn.tag = i
            btn.setImage(UIImage(systemName: "star"), for: .normal)
            btn.tintColor = .systemGray4
            btn.addTarget(self, action: #selector(starTapped(_:)), for: .touchUpInside)
            starStack.addArrangedSubview(btn)
        }
        
        commentField.placeholder = "Tulis komentar (opsional)..."
        commentField.borderStyle = .roundedRect
        
        submitButton.setTitle("Kirim Ulasan", for: .normal)
        submitButton.backgroundColor = Brand.primary; submitButton.setTitleColor(.white, for: .normal)
        submitButton.roundCorners(radius: 8)
        submitButton.addTarget(self, action: #selector(submitTapped), for: .touchUpInside)
        
        let mainStack = UIStackView(arrangedSubviews: [starStack, commentField, submitButton])
        mainStack.axis = .vertical; mainStack.spacing = 16
        contentView.addSubview(mainStack)
        mainStack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(16) }
        starStack.snp.makeConstraints { make in make.height.equalTo(44) }
        submitButton.snp.makeConstraints { make in make.height.equalTo(44) }
    }
    
    @objc private func starTapped(_ sender: UIButton) {
        currentRating = sender.tag
        for (idx, view) in starStack.arrangedSubviews.enumerated() {
            let btn = view as? UIButton
            let isSelected = idx < currentRating
            btn?.setImage(UIImage(systemName: isSelected ? "star.fill" : "star"), for: .normal)
            btn?.tintColor = isSelected ? .systemYellow : .systemGray4
        }
    }
    
    @objc private func submitTapped() {
        guard currentRating > 0 else { return }
        onRatingSubmit?(currentRating, commentField.text ?? "")
    }
    
    func configure(rating: Int?, comment: String?) {
        if let r = rating {
            currentRating = r
            for (idx, view) in starStack.arrangedSubviews.enumerated() {
                let btn = view as? UIButton
                let isSelected = idx < r
                btn?.setImage(UIImage(systemName: isSelected ? "star.fill" : "star"), for: .normal)
                btn?.tintColor = isSelected ? .systemYellow : .systemGray4
                btn?.isUserInteractionEnabled = false
            }
            commentField.text = comment
            commentField.isUserInteractionEnabled = false
            submitButton.isHidden = true
        } else {
            submitButton.isHidden = false
            commentField.isUserInteractionEnabled = true
            for view in starStack.arrangedSubviews { view.isUserInteractionEnabled = true }
        }
    }
}
