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
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "OR"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let googleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign in with Google", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.backgroundColor = .white
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setImage(UIImage(systemName: "g.circle.fill"), for: .normal) // Placeholder for Google Logo
        button.tintColor = .systemRed
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 10)
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
        
        let loginStack = UIStackView(arrangedSubviews: [loginButton, biometricButton])
        loginStack.axis = .horizontal
        loginStack.spacing = 12
        loginStack.alignment = .fill
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, emailTextField, passwordTextField, loginStack, orLabel, googleButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        view.addSubview(activityIndicator)
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        biometricButton.snp.makeConstraints { make in
            make.width.equalTo(50)
        }
        
        googleButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(loginButton)
        }
        
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        biometricButton.addTarget(self, action: #selector(handleBiometricLogin), for: .touchUpInside)
    }
    
    @objc private func handleGoogleSignIn() {
        setLoading(true)
        
        // Placeholder for GIDSignIn.sharedInstance.signIn
        // Upon success, get the idToken and call:
        // try await AuthManager.shared.googleLogin(idToken: token)
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
