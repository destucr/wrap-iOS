import UIKit
import LocalAuthentication
import SnapKit
import GoogleSignIn

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
    
    private let orLabel: UILabel = {
        let label = UILabel()
        label.text = "OR"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()
    
    private let googleButton: UIButton = {
        // 1. Start with a plain configuration
        var config = UIButton.Configuration.plain()

        // 2. Set the Title and Font
        config.title = "Sign in with Google"
        config.baseForegroundColor = .label // Respects Light/Dark mode text color
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .systemFont(ofSize: 16, weight: .medium)
            return outgoing
        }

        // 3. Add the Image (Ensure "google_logo" is in your Assets)
        config.image = UIImage(named: "google_logo")?.withRenderingMode(.alwaysOriginal)
        config.imagePadding = 10
        config.imagePlacement = .leading

        // 4. Create the Bordered Background
        config.background.backgroundColor = .systemBackground
        config.background.strokeColor = .systemGray4
        config.background.strokeWidth = 1.0
        config.background.cornerRadius = 8

        // 5. Apply to button
        let button = UIButton(configuration: config)
        return button
    }()


    private let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Login", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()

    private let forgotPasswordButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Forgot Password?", for: .normal)
        button.setTitleColor(Brand.primary, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        return button
    }()

    private let biometricButton: UIButton = {
        let button = UIButton(type: .system)
        let icon = BiometricManager.shared.biometricType == .faceID ? "faceid" : "touchid"
        button.setImage(UIImage(systemName: icon), for: .normal)
        button.tintColor = .systemBlue
        
        // Deterministic check: Is it available AND enabled by the user?
        button.isHidden = !BiometricManager.shared.canAuthenticate() || !AuthManager.shared.isBiometricsEnabled
        return button
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkBiometricPreference()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let loginStack = UIStackView(arrangedSubviews: [loginButton, biometricButton])
        loginStack.axis = .horizontal
        loginStack.spacing = 12
        loginStack.alignment = .fill
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, emailTextField, passwordTextField, forgotPasswordButton, loginStack, orLabel, googleButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        view.addSubview(activityIndicator)
        
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        forgotPasswordButton.snp.makeConstraints { make in
            make.height.equalTo(20)
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
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
        googleButton.addTarget(self, action: #selector(handleGoogleSignIn), for: .touchUpInside)
        biometricButton.addTarget(self, action: #selector(handleBiometricLogin), for: .touchUpInside)
    }
    
    @objc private func handleForgotPassword() {
        coordinator?.showForgotPassword()
    }
    
    @objc private func handleGoogleSignIn() {
        setLoading(true)
        
        GIDSignIn.sharedInstance.signIn(withPresenting: self) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                self.setLoading(false)
                // Ignore if user cancelled
                if (error as NSError).code != GIDSignInError.canceled.rawValue {
                    self.showAlert(message: "Google Sign-In failed: \(error.localizedDescription)")
                }
                return
            }
            
            guard let user = result?.user, 
                  let idToken = user.idToken?.tokenString else {
                self.setLoading(false)
                return
            }
            
            let accessToken = user.accessToken.tokenString
            
            Task {
                do {
                    try await AuthManager.shared.googleLogin(idToken: idToken, accessToken: accessToken)
                    self.setLoading(false)
                    self.coordinator?.showCatalog()
                } catch {
                    self.setLoading(false)
                    self.showAlert(message: "Backend verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func checkBiometricPreference() {
        if AuthManager.shared.isBiometricsEnabled,
           BiometricManager.shared.canAuthenticate(),
           AuthManager.shared.getCredentials() != nil {
            // Frictionless entry: Auto-trigger biometric login
            handleBiometricLogin()
        }
    }
    
    @objc private func handleBiometricLogin() {
        guard let credentials = AuthManager.shared.getCredentials() else {
            showAlert(message: "Please login manually once to enable Biometrics.")
            return
        }
        
        setLoading(true)
        
        BiometricManager.shared.authenticate(reason: "Login to Wrap") { [weak self] success, error in
            guard let self = self else { return }
            
            if success {
                Task { [weak self] in
                    do {
                        _ = try await AuthManager.shared.login(email: credentials.email, password: credentials.password)
                        self?.setLoading(false)
                        self?.coordinator?.showCatalog()
                    } catch {
                        self?.setLoading(false)
                        self?.showAlert(message: "Biometric login failed. Please use your password.")
                    }
                }
            } else {
                self.setLoading(false)
                if let error = error as? LAError, error.code != .userCancel {
                    self.showAlert(message: "Authentication failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func handleLogin() {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else { return }
        
        setLoading(true)
        
        Task { [weak self] in
            do {
                let response = try await AuthManager.shared.login(email: email, password: password)
                
                // Save credentials to Keychain for future Biometric Logins
                AuthManager.shared.saveCredentials(email: email, password: password)
                
                self?.setLoading(false)
                print("Login Success! Token: \(response.token)")
                self?.coordinator?.showCatalog()
            } catch {
                print("❌ [UI] Login Action Failed: \(error)")
                self?.setLoading(false)
                self?.showAlert(message: "Login failed: \(error.localizedDescription)")
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
