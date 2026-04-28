import UIKit
import SnapKit

class ProfileViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "My Profile"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        return label
    }()
    
    private let logoutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Logout", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    private let biometricLabel: UILabel = {
        let label = UILabel()
        label.text = "Enable Biometric Login"
        label.font = .systemFont(ofSize: 18)
        return label
    }()
    
    private let biometricSwitch: UISwitch = {
        let sw = UISwitch()
        sw.onTintColor = Brand.primary
        return sw
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchProfile()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(biometricLabel)
        view.addSubview(biometricSwitch)
        view.addSubview(logoutButton)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.snp.topMargin).offset(40)
            make.leading.equalToSuperview().offset(20)
        }
        
        biometricLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.leading.equalToSuperview().offset(20)
        }
        
        biometricSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(biometricLabel)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        logoutButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.snp.bottomMargin).offset(-40)
            make.centerX.equalToSuperview()
        }
        
        logoutButton.addTarget(self, action: #selector(handleLogout), for: .touchUpInside)
        biometricSwitch.addTarget(self, action: #selector(handleBiometricToggle), for: .valueChanged)
    }
    
    private func fetchProfile() {
        // Implementation would call /user/profile and set biometricSwitch.isOn
    }
    
    @objc private func handleBiometricToggle() {
        let isEnabled = biometricSwitch.isOn
        
        // Update preference in backend
        // Endpoint: PUT /api/v1/user/settings { "biometrics_enabled": isEnabled }
    }
    
    @objc private func handleLogout() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive, handler: { _ in
            NetworkManager.shared.setAuthToken("") // Clear token (This triggers Keychain deletion in NetworkManager)
            self.coordinator?.showLogin()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}
