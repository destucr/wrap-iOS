import UIKit
import SnapKit
import Hero

class SearchViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private var results: [Product] = []
    private var searchTask: Task<Void, Never>?
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Cari produk favoritmu..."
        sb.searchBarStyle = .minimal
        return sb
    }()
    
    private let tableView: UITableView = {
        let tv = UITableView()
        tv.separatorStyle = .none
        tv.backgroundColor = .secondarySystemBackground
        return tv
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Mulai cari produk favoritmu"
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.isHidden = false
        return label
    }()
    
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchBar.becomeFirstResponder()
    }
    
    private func setupNavigationBar() {
        navigationItem.titleView = searchBar
        searchBar.delegate = self
        
        // Ensure we have a back button even with titleView
        navigationItem.backButtonDisplayMode = .minimal
    }
    
    private func setupUI() {
        view.backgroundColor = .secondarySystemBackground
        
        view.addSubview(tableView)
        view.addSubview(emptyStateLabel)
        view.addSubview(activityIndicator)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(ProductCell.self, forCellReuseIdentifier: ProductCell.identifier)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func performSearch(query: String) {
        searchTask?.cancel()
        
        if query.isEmpty {
            results = []
            tableView.reloadData()
            emptyStateLabel.isHidden = false
            emptyStateLabel.text = "Mulai cari produk favoritmu"
            return
        }
        
        emptyStateLabel.isHidden = true
        activityIndicator.startAnimating()
        
        searchTask = Task {
            do {
                let fetchedResults = try await CatalogService.shared.searchProducts(query: query)
                
                guard !Task.isCancelled else { return }
                
                self.results = fetchedResults
                self.tableView.reloadData()
                self.activityIndicator.stopAnimating()
                
                if results.isEmpty {
                    emptyStateLabel.isHidden = false
                    emptyStateLabel.text = "Produk tidak ditemukan"
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.activityIndicator.stopAnimating()
                print("Search error: \(error)")
            }
        }
    }
}

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        performSearch(query: searchText)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProductCell.identifier, for: indexPath) as? ProductCell else {
            return UITableViewCell()
        }
        cell.configure(with: results[indexPath.row])
        cell.delegate = self
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let product = results[indexPath.row]
        coordinator?.showProductDetail(productId: product.id)
    }
}

extension SearchViewController: ProductCellDelegate {
    func productCell(_ cell: ProductCell, didUpdateQuantity quantity: Int, for product: Product) {
        guard let firstVariant = product.variants?.first else { return }
        let price = firstVariant.priceOverride ?? product.basePrice
        CartManager.shared.setQuantity(variantId: firstVariant.id, quantity: quantity, name: product.name, price: price)
    }
}
