import UIKit
import SnapKit
import Hero
import Combine

@MainActor
final class HomeViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    private let viewModel = HomeViewModel()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Components
    
    private let addressBar: UIView = {
        let view = UIView()
        let icon = UIImageView(image: UIImage(systemName: "mappin.circle.fill"))
        icon.tintColor = Brand.primary
        view.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        return view
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Mengirim ke..."
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = Brand.Text.primary
        return label
    }()
    
    private let searchBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0)
        view.layer.cornerRadius = 12
        
        let icon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        icon.tintColor = .systemGray
        view.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(18)
        }
        
        let label = UILabel()
        label.text = "Cari produk favoritmu..."
        label.textColor = .systemGray
        label.font = .systemFont(ofSize: 15)
        view.addSubview(label)
        label.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.centerY.equalToSuperview()
        }
        
        return view
    }()
    
    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        cv.backgroundColor = .white
        cv.register(ProductCardView.self, forCellWithReuseIdentifier: ProductCardView.identifier)
        cv.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.identifier)
        cv.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        cv.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
        loadData()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        collectionView.reloadData()
    }
    
    private func setupObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(cartDidUpdate), name: .cartUpdated, object: nil)
    }
    
    @objc private func cartDidUpdate() {
        collectionView.reloadData()
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(addressBar)
        addressBar.addSubview(addressLabel)
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        
        // ELITE: Use a single "Live" layout that captures the viewModel state
        let layout = HomeLayoutProvider.createLayout(viewModel: viewModel)
        collectionView.setCollectionViewLayout(layout, animated: false)
        
        addressBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(4)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(30)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(40)
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(addressBar.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }

        let searchTap = UITapGestureRecognizer(target: self, action: #selector(didTapSearch))
        searchBar.addGestureRecognizer(searchTap)
        searchBar.isUserInteractionEnabled = true
    }
    
    private func bindViewModel() {
        // ELITE: Now we only need to reload data. The "Live" layout updates itself dynamically.
        Publishers.CombineLatest(viewModel.$sections, viewModel.$isLoading)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.collectionView.reloadData()
            }
            .store(in: &cancellables)
            
        viewModel.$addressText
            .receive(on: RunLoop.main)
            .map { Optional($0) }
            .assign(to: \.text, on: addressLabel)
            .store(in: &cancellables)
    }
    
    private func loadData() {
        Task {
            await viewModel.fetchData()
        }
    }
    
    @objc private func didTapSearch() {
        coordinator?.showSearch()
    }
}

// MARK: - CollectionView DataSource & Delegate

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.isLoading ? 3 : viewModel.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if viewModel.isLoading {
            if section == 0 { return 1 } // Banner
            if section == 1 { return 5 } // Categories
            return 4 // Products
        }
        
        switch viewModel.sections[section] {
        case .banners(let banners): return banners.count
        case .categories(let categories): return categories.count
        case .products(_, let items): return items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if viewModel.isLoading {
            if indexPath.section == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.identifier, for: indexPath) as! BannerCell
                cell.startShimmering()
                return cell
            } else if indexPath.section == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
                cell.startShimmering()
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
                cell.startLoading()
                return cell
            }
        }
        
        let section = viewModel.sections[indexPath.section]
        
        switch section {
        case .banners(let banners):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.identifier, for: indexPath) as! BannerCell
            cell.stopShimmering()
            cell.configure(with: banners[indexPath.item])
            return cell
        case .categories(let categories):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
            cell.stopShimmering()
            cell.configure(with: categories[indexPath.item])
            return cell
        case .products(_, let items):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
            cell.configure(with: items[indexPath.item])
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
            if case .products(let title, _) = viewModel.sections[indexPath.section] {
                header.configure(with: title)
            }
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard !viewModel.isLoading else { return }
        let section = viewModel.sections[indexPath.section]
        switch section {
        case .categories(let categories):
            coordinator?.showCatalogCategory(category: categories[indexPath.item])
        case .products(_, let items):
            coordinator?.showProductDetail(productId: items[indexPath.item].id)
        default:
            break
        }
    }
}
