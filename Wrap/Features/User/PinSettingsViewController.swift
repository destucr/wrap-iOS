import UIKit
import SnapKit

final class PinSettingsViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private let pinTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter 6-digit PIN"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.isSecureTextEntry = true
        return tf
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Set PIN", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "PIN Settings"
        
        view.addSubview(pinTextField)
        view.addSubview(saveButton)
        
        pinTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(44)
        }
        
        saveButton.snp.makeConstraints { make in
            make.top.equalTo(pinTextField.snp.bottom).offset(20)
            make.leading.trailing.equalTo(pinTextField)
            make.height.equalTo(50)
        }
        
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }
    
    @objc private func handleSave() {
        guard let pin = pinTextField.text, pin.count == 6 else {
            let alert = UIAlertController(title: "Error", message: "PIN must be 6 digits", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        Task {
            do {
                let payload = ["pin": pin]
                let body = try JSONSerialization.data(withJSONObject: payload)
                let _: [String: String] = try await NetworkManager.shared.request(endpoint: "/user/pin", method: "POST", body: body)
                self.navigationController?.popViewController(animated: true)
            } catch {
                let alert = UIAlertController(title: "Error", message: "Failed to set PIN: \(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
            }
        }
    }
}
