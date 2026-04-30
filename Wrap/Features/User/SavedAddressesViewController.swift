import UIKit
import SnapKit

final class SavedAddressesViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var addresses: [SavedAddress] = []
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .grouped)
        return tv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchAddresses()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Saved Addresses"
        
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AddressCell")
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleAddAddress))
    }
    
    private func fetchAddresses() {
        Task {
            do {
                // You'll need to define SavedAddress in a shared model or iOS model file
                // let response: [SavedAddress] = try await NetworkManager.shared.request(endpoint: "/user/addresses")
                // self.addresses = response
                // tableView.reloadData()
            } catch {
                print("Failed to fetch addresses: \(error)")
            }
        }
    }
    
    @objc private func handleAddAddress() {
        // Navigation to Add Address form
    }
}

extension SavedAddressesViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return addresses.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AddressCell", for: indexPath)
        cell.textLabel?.text = addresses[indexPath.row].label
        return cell
    }
}
