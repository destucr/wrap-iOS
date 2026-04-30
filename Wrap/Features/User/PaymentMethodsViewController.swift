import UIKit
import SnapKit
import SafariServices

@MainActor
final class PaymentMethodsViewController: UIViewController {
    
    private var accounts: [LinkedAccount] = []
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAccounts()
    }
    
    private func setupUI() {
        title = "Metode Pembayaran"
        view.backgroundColor = Brand.secondary
        
        view.addSubview(tableView)
        view.addSubview(activityIndicator)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(LinkedAccountCell.self, forCellReuseIdentifier: LinkedAccountCell.identifier)
        tableView.register(AddPaymentMethodCell.self, forCellReuseIdentifier: AddPaymentMethodCell.identifier)
    }
    
    private func fetchAccounts() {
        activityIndicator.startAnimating()
        Task {
            do {
                self.accounts = try await PaymentService.shared.fetchLinkedAccounts()
                tableView.reloadData()
                activityIndicator.stopAnimating()
            } catch {
                activityIndicator.stopAnimating()
                print("Failed to fetch accounts: \(error)")
            }
        }
    }
    
    private func startLinking(channelCode: String) {
        activityIndicator.startAnimating()
        Task {
            do {
                let urlString = try await PaymentService.shared.initializeLinking(channelCode: channelCode)
                activityIndicator.stopAnimating()
                if let url = URL(string: urlString) {
                    let safariVC = SFSafariViewController(url: url)
                    safariVC.delegate = self
                    present(safariVC, animated: true)
                } else {
                    showAlert(message: "Failed to parse redirect URL.")
                }
            } catch {
                activityIndicator.stopAnimating()
                print("Failed to initialize linking: \(error)")
                showAlert(message: "Gagal menghubungkan akun: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Informasi", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension PaymentMethodsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return accounts.count
        } else {
            return 2 // OVO and DANA
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Akun Terhubung" : "Tambah Baru"
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: LinkedAccountCell.identifier, for: indexPath) as! LinkedAccountCell
            cell.configure(with: accounts[indexPath.row])
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: AddPaymentMethodCell.identifier, for: indexPath) as! AddPaymentMethodCell
            let channel = indexPath.row == 0 ? "OVO" : "DANA"
            cell.configure(title: channel)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 1 {
            let channelCode = indexPath.row == 0 ? "ID_OVO" : "ID_DANA"
            startLinking(channelCode: channelCode)
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.section == 0 {
            let deleteAction = UIContextualAction(style: .destructive, title: "Hapus") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                let account = self.accounts[indexPath.row]
                Task {
                    do {
                        try await PaymentService.shared.unlinkAccount(id: account.id)
                        self.accounts.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                        completion(true)
                    } catch {
                        completion(false)
                    }
                }
            }
            return UISwipeActionsConfiguration(actions: [deleteAction])
        }
        return nil
    }
}

extension PaymentMethodsViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // Refresh accounts when user returns from Safari
        fetchAccounts()
    }
}

// MARK: - Cells

final class LinkedAccountCell: UITableViewCell {
    static let identifier = "LinkedAccountCell"
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let balanceLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, detailLabel])
        stack.axis = .vertical
        stack.spacing = 2
        
        contentView.addSubview(stack)
        contentView.addSubview(balanceLabel)
        
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        balanceLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        titleLabel.font = .systemFont(ofSize: 16, weight: .bold)
        detailLabel.font = .systemFont(ofSize: 12)
        detailLabel.textColor = .secondaryLabel
        balanceLabel.font = .systemFont(ofSize: 14, weight: .thin)
        balanceLabel.textColor = Brand.primary
    }
    
    func configure(with account: LinkedAccount) {
        titleLabel.text = account.channelCode.replacingOccurrences(of: "ID_", with: "")
        detailLabel.text = account.accountDetails
        if let balance = account.balance {
            balanceLabel.text = balance.formattedIDR
        } else {
            balanceLabel.text = ""
        }
    }
}

final class AddPaymentMethodCell: UITableViewCell {
    static let identifier = "AddPaymentMethodCell"
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        textLabel?.font = .systemFont(ofSize: 16)
        accessoryType = .disclosureIndicator
    }
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(title: String) {
        textLabel?.text = "Hubungkan \(title)"
    }
}
