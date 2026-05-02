import UIKit
import SnapKit

final class SavedAddressesViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var addresses: [SavedAddress] = []
    var onSelectAddress: ((SavedAddress) -> Void)?
    
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
                self.addresses = try await UserService.shared.fetchSavedAddresses()
                tableView.reloadData()
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
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "AddressCell")
        let addr = addresses[indexPath.row]
        cell.textLabel?.text = addr.label
        cell.textLabel?.font = .systemFont(ofSize: 15, weight: .bold)
        cell.detailTextLabel?.text = addr.fullAddress
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 2
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let addr = addresses[indexPath.row]
        onSelectAddress?(addr)
    }
}
