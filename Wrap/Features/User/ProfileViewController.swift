import UIKit
import SnapKit
import Combine
import SkeletonView

final class ProfileViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let viewModel = ProfileViewModel()
    private var cancellables = Set<AnyCancellable>()
    private var userData: UserData?
    
    private enum Section: Int, CaseIterable {
        case account
        case payments
        case security
        case logistics
        case system
        
        var title: String? {
            switch self {
            case .account: return "Informasi Akun"
            case .payments: return "Pembayaran"
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
        label.text = "---"
        label.font = Brand.Typography.header(size: 24)
        label.isSkeletonable = true
        label.linesCornerRadius = 4
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "---"
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 1
        label.isSkeletonable = true
        label.linesCornerRadius = 4
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
        bindViewModel()
        viewModel.fetchProfile()
    }
    
    private func bindViewModel() {
        viewModel.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(with: state)
            }
            .store(in: &cancellables)
    }
    
    private func updateUI(with state: ViewState<UserData>) {
        switch state {
        case .idle:
            headerView.hideSkeleton()
            tableView.hideSkeleton()
        case .loading:
            headerView.showAnimatedGradientSkeleton()
            tableView.showAnimatedGradientSkeleton()
        case .success(let user):
            headerView.hideSkeleton()
            tableView.hideSkeleton()
            self.userData = user
            nameLabel.text = user.fullName
            addressLabel.text = user.email
            
            if biometricSwitch.isOn != user.biometricsEnabled {
                biometricSwitch.setOn(user.biometricsEnabled, animated: true)
                AuthManager.shared.isBiometricsEnabled = user.biometricsEnabled
            }
            tableView.reloadData()
        case .error(let message):
            headerView.hideSkeleton()
            tableView.hideSkeleton()
            nameLabel.text = "Gagal"
            addressLabel.text = message
        }
    }
    
    private func setupUI() {
        view.backgroundColor = Brand.secondary
        title = "Profile"
        view.isSkeletonable = true
        
        view.addSubview(tableView)
        tableView.isSkeletonable = true
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
        headerView.isSkeletonable = true
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
    
    @objc private func handleBiometricToggle() {
        let isEnabled = biometricSwitch.isOn
        AuthManager.shared.isBiometricsEnabled = isEnabled
        
        Task {
            do {
                try await UserService.shared.updateSettings(biometricsEnabled: isEnabled)
            } catch {
                print("Failed to update biometric preference: \(error)")
            }
        }
    }
    
    @objc private func handleLogout() {
        let alert = UIAlertController(title: "Logout", message: "Apakah Anda yakin ingin keluar?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            Task {
                try? await UserService.shared.logout()
                AuthManager.shared.logout()
                CartManager.shared.clear()
                self.coordinator?.showLogin()
            }
        }))
        alert.addAction(UIAlertAction(title: "Batal", style: .cancel))
        present(alert, animated: true)
    }
}

extension ProfileViewController: UITableViewDataSource, UITableViewDelegate, SkeletonTableViewDataSource {
    
    func collectionSkeletonView(_ skeletonView: UITableView, cellIdentifierForRowAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return "DefaultCell"
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let section = Section(rawValue: section) else { return 0 }
        switch section {
        case .account: return 3
        case .payments: return 1
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
            if indexPath.row == 0 {
                cell.textLabel?.text = "Nama"
                cell.detailTextLabel?.text = userData?.fullName
            } else if indexPath.row == 1 {
                cell.textLabel?.text = "Telepon"
                cell.detailTextLabel?.text = userData?.phoneNumber ?? "-"
            } else {
                cell.textLabel?.text = "Alamat"
                cell.detailTextLabel?.text = userData?.fullAddress ?? "Belum diatur"
            }
        case .payments:
            cell.textLabel?.text = "Metode Pembayaran"
            cell.imageView?.image = UIImage(systemName: "creditcard")
            cell.imageView?.tintColor = Brand.primary
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
            coordinator?.showAccountDetails()
        case .payments:
            let vc = PaymentMethodsViewController()
            navigationController?.pushViewController(vc, animated: true)
        case .security:
            if indexPath.row == 1 {
                coordinator?.showPinSettings()
            }
        case .logistics:
            coordinator?.showSavedAddresses()
        case .system:
            handleLogout()
        }
    }
}
