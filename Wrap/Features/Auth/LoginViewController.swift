import UIKit
import SnapKit

class LoginViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    // UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Wrap"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let emailTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Email"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .emailAddress
        tf.autocapitalizationType = .none
        return tf
    }()
    
    private let passwordTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Password"
        tf.borderStyle = .roundedRect
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    private let biometricButton: UIButton = {
        let button = UIButton(type: .system)
        let icon = BiometricManager.shared.biometricType == .faceID ? "faceid" : "touchid"
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .systemBlue
        button.isHidden = !BiometricManager.shared.canAuthenticate()
        return button
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkBiometricPreference()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, emailTextField, passwordTextField, loginButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        view.addSubview(biometricButton)
        view.addSubview(activityIndicator)
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        biometricButton.snp.makeConstraints { make in
            make.top.equalTo(stackView.bottomAnchor).offset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(50)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(loginButton)
        }
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        biometricButton.addTarget(self, action: #selector(handleBiometricLogin), for: .touchUpInside)
    }
    
    private func checkBiometricPreference() {
        // Logic to check if user enabled biometrics (from Local Defaults or Keychain)
        // If enabled, automatically trigger handleBiometricLogin()
    }
    
    @objc private func handleBiometricLogin() {
        BiometricManager.shared.authenticate(reason: "Login to Wrap") { [weak self] success, error in
            if success {
                // Biometric success, now retrieve credentials from Keychain and call AuthManager.shared.login
                self?.coordinator?.showCatalog()
            } else if let error = error {
                print("Biometric Authentication Failed: \(error.localizedDescription)")
            }
        }
    }
    
    @objc private func handleLogin() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else { return }
        
        setLoading(true)
        
        Task {
            do {
                let response = try await AuthManager.shared.login(email: email, password: password)
                setLoading(false)
                print("Login Success! Token: \(response.token)")
                coordinator?.showCatalog()
            } catch {
                setLoading(false)
                showAlert(message: "Login failed: \(error)")
            }
        }
    }
    
    private func setLoading(_ isLoading: Bool) {
        loginButton.isEnabled = !isLoading
        loginButton.setTitle(isLoading ? "" : "Login", for: .normal)
        isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Visual Documentation (Xcode 15+ Preview)
#Preview {
    LoginViewController()
}
