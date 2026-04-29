import UIKit
import SnapKit

class ForgotPasswordViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Forgot Password"
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Enter your email address and we'll send you a link to reset your password."
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
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
    
    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Send Reset Link", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        return button
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Forgot Password"
        
        let stackView = UIStackView(arrangedSubviews: [titleLabel, descriptionLabel, emailTextField, sendButton])
        stackView.axis = .vertical
        stackView.spacing = 20
        
        view.addSubview(stackView)
        view.addSubview(activityIndicator)
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        sendButton.snp.makeConstraints { make in
            make.height.equalTo(50)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(sendButton)
        }
        
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
    }
    
    @objc private func handleSend() {
        guard let email = emailTextField.text, !email.isEmpty else { return }
        
        setLoading(true)
        
        Task {
            do {
                try await AuthService.shared.forgotPassword(email: email)
                setLoading(false)
                showAlert(title: "Success", message: "A reset link has been sent to your email.") {
                    self.navigationController?.popViewController(animated: true)
                }
            } catch {
                setLoading(false)
                showAlert(title: "Error", message: "Failed to send reset link. Please try again.")
            }
        }
    }
    
    private func setLoading(_ isLoading: Bool) {
        sendButton.isEnabled = !isLoading
        sendButton.setTitle(isLoading ? "" : "Send Reset Link", for: .normal)
        isLoading ? activityIndicator.startAnimating() : activityIndicator.stopAnimating()
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
