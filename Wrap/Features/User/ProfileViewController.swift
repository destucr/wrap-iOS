import UIKit
import SnapKit

final class ProfileViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private enum Section: Int, CaseIterable {
        case account
        case security
        case logistics
        case system
        
        var title: String? {
            switch self {
            case .account: return "Informasi Akun"
            case .security: return "Keamanan"
            case .logistics: return "Logistik"
            case .system: return nil
            }
        }
    }
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = Brand.secondary
        return tv
    }()
    
    // Header View Components
    private let headerView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 120))
        return view
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading..."
        label.font = Brand.Typography.header(size: 24)
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Fetching address..."
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        return label
    }()
    
    private let biometricSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = Brand.primary
        sw.isOn = AuthManager.shared.isBiometricsEnabled
        return sw
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = Brand.secondary
        title = "Profile"
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
        }
        
        setupHeader()
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "DefaultCell")
        
        biometricSwitch.addTarget(self, action: #selector(handleBiometricToggle), for: .valueChanged)
    }
    
    private func setupHeader() {
        headerView.addSubview(nameLabel)
        headerView.addSubview(addressLabel)
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(nameLabel)
        }
        
        tableView.tableHeaderView = headerView
    }
    
    private func fetchProfile() {
        Task {
            do {
                let user: UserData = try await NetworkManager.shared.request(endpoint: "/user/profile")
                nameLabel.text = user.fullName
                addressLabel.text = user.email // Fallback to email if address is nil
                
                if biometricSwitch.isOn != user.biometricsEnabled {
                    biometricSwitch.setOn(user.biometricsEnabled, animated: true)
                    AuthManager.shared.isBiometricsEnabled = user.biometricsEnabled
                }
                tableView.reloadData()
            } catch {
                print("Failed to fetch profile: \(error)")
            }
        }
    }
    
    @objc private func handleBiometricToggle() {
        let isEnabled = biometricSwitch.isOn
        AuthManager.shared.isBiometricsEnabled = isEnabled
        
        Task {
            do {
                let body = ["biometrics_enabled": isEnabled]
                let jsonData = try JSONSerialization.data(withJSONObject: body)
                let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/settings", method: "PUT", body: jsonData)
            } catch {
                print("Failed to update biometric preference: \(error)")
            }
        }
    }
    
    @objc private func handleLogout() {
        let alert = UIAlertController(title: "Logout", message: "Apakah Anda yakin ingin keluar?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            Task {
                _ = try? await NetworkManager.shared.request(endpoint: "/user/logout", method: "POST") as [String: String]
                NetworkManager.shared.setAuthToken("")
                self.coordinator?.showLogin()
            }
        }))
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .account: return 1
        case .security: return 2
        case .logistics: return 1
        case .system: return 1
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return Section(rawValue: section)?.title
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "DefaultCell")
        cell.accessoryType = .disclosureIndicator
        
        guard let section = Section(rawValue: indexPath.section) else { return cell }
        
        switch section {
        case .account:
            cell.textLabel?.text = "Detail Akun"
            cell.detailTextLabel?.text = ""
        case .security:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Biometric Login"
                cell.accessoryView = biometricSwitch
                cell.selectionStyle = .none
            } else {
                cell.textLabel?.text = "Pin Settings"
            }
        case .logistics:
            cell.textLabel?.text = "Alamat Tersimpan"
        case .system:
            cell.textLabel?.text = "Logout"
            cell.textLabel?.textColor = .systemRed
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let section = Section(rawValue: indexPath.section) else { return }
        
        switch section {
        case .account:
            // Navigation to Account Details
            break
        case .security:
            if indexPath.row == 1 {
                // Navigation to PIN Settings
                break
            }
        case .logistics:
            // Navigation to Saved Addresses
            break
        case .system:
            handleLogout()
        }
    }
}
