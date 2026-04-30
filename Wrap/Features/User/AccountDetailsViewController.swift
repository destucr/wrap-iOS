import UIKit
import SnapKit
import CoreLocation

final class AccountDetailsViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var currentCoords: CLLocationCoordinate2D?
    private var currentAddress: String?
    private var currentPostalCode: String?
    
    private let nameTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Nama Lengkap"
        tf.borderStyle = .roundedRect
        return tf
    }()
    
    private let phoneTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Nomor Telepon"
        tf.borderStyle = .roundedRect
        tf.keyboardType = .phonePad
        return tf
    }()
    
    private let addressButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.gray()
        config.title = "Set Alamat pada Peta"
        config.image = UIImage(systemName: "map.fill")
        config.imagePadding = 10
        config.imagePlacement = .leading
        config.baseForegroundColor = .label
        config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
        
        // Handle overflow with multiline support
        config.titleLineBreakMode = .byWordWrapping
        
        button.configuration = config
        button.contentHorizontalAlignment = .leading
        button.layer.cornerRadius = 8
        button.titleLabel?.numberOfLines = 0
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Simpan", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .bold)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchUserData()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Detail Akun"
        
        let stack = UIStackView(arrangedSubviews: [nameTextField, phoneTextField, addressButton, saveButton])
        stack.axis = .vertical
        stack.spacing = 20
        view.addSubview(stack)
        
        stack.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        
        [nameTextField, phoneTextField].forEach { $0.snp.makeConstraints { $0.height.equalTo(44) } }
        
        // Allow addressButton to grow based on multiline content
        addressButton.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(50)
        }
        
        saveButton.snp.makeConstraints { make in
            make.height.equalTo(56)
        }
        
        addressButton.addTarget(self, action: #selector(handleAddressTap), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
    }
    
    @objc private func handleAddressTap() {
        coordinator?.showAddressMap { [weak self] coord, addr, zip in
            self?.currentCoords = coord
            self?.currentAddress = addr
            self?.currentPostalCode = zip
            self?.addressButton.configuration?.title = addr
        }
    }
    
    private func fetchUserData() {
        Task {
            do {
                let user = try await UserService.shared.fetchProfile()
                nameTextField.text = user.fullName
                phoneTextField.text = user.phoneNumber 
                currentAddress = user.fullAddress
                currentPostalCode = user.postalCode
                
                if let lat = user.latitude, let lon = user.longitude {
                    currentCoords = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                }
                
                addressButton.configuration?.title = user.fullAddress ?? "Set Alamat pada Peta"
            } catch {
                print("Failed to fetch user data: \(error)")
            }
        }
    }
    
    @objc private func handleSave() {
        guard let name = nameTextField.text, !name.isEmpty,
              let phone = phoneTextField.text, !phone.isEmpty else { 
            showAlert(message: "Nama dan Telepon wajib diisi")
            return 
        }
        
        Task {
            do {
                // Update Phone
                try await UserService.shared.updatePhoneNumber(phoneNumber: phone)
                
                // Update Address
                let lat = currentCoords?.latitude ?? -7.388883
                let lon = currentCoords?.longitude ?? 109.360697
                let addr = currentAddress ?? "Purbalingga"
                let zip = currentPostalCode ?? "53311" // Purbalingga default zip
                
                try await UserService.shared.updateProfile(fullName: name, address: addr, postalCode: zip, lat: lat, lon: lon)
                
                self.navigationController?.popViewController(animated: true)
            } catch {
                showAlert(message: "Gagal memperbarui detail: \(error.localizedDescription)")
            }
        }
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Detail Akun", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
