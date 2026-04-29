import UIKit
import Kingfisher
import SnapKit
import Hero

@MainActor
final class HomeViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private enum Section: Hashable {
        case banners([PromoBanner])
        case categories([CatalogCategory])
        case products(title: String, items: [Product])
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .banners: hasher.combine(0)
            case .categories: hasher.combine(1)
            case .products(let title, _): hasher.combine(title)
            }
        }
        
        static func == (lhs: Section, rhs: Section) -> Bool {
            switch (lhs, rhs) {
            case (.banners, .banners): return true
            case (.categories, .categories): return true
            case (.products(let lTitle, _), .products(let rTitle, _)): return lTitle == rTitle
            default: return false
            }
        }
    }
    
    private var feed: HomeFeedData?
    private var sections: [Section] = []
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.text = "Mengirim ke: Sedang memuat..."
        label.textColor = Brand.Text.primary
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        return label
    }()
    
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
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.register(ProductCardView.self, forCellWithReuseIdentifier: ProductCardView.identifier)
        cv.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.identifier)
        cv.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        cv.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
        fetchProfile()
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
    
    @objc private func didTapSearch() {
        coordinator?.showSearch()
    }
    
    private func fetchData() {
        Task {
            do {
                let fetchedFeed: HomeFeedData = try await NetworkManager.shared.request(endpoint: "/catalog/home")
                self.feed = fetchedFeed
                
                var newSections: [Section] = []
                if !fetchedFeed.banners.isEmpty {
                    newSections.append(.banners(fetchedFeed.banners))
                }
                if !fetchedFeed.categories.isEmpty {
                    newSections.append(.categories(fetchedFeed.categories))
                }
                for feedSection in fetchedFeed.sections {
                    newSections.append(.products(title: feedSection.title, items: feedSection.items))
                }
                
                self.sections = newSections
                self.collectionView.reloadData()
            } catch {
                print("Failed to fetch home data: \(error)")
            }
        }
    }
    
    private func fetchProfile() {
        Task {
            do {
                let user: UserData = try await NetworkManager.shared.request(endpoint: "/user/profile")
                let address = user.fullAddress ?? user.email
                addressLabel.text = "Mengirim ke: \(address)"
            } catch {
                print("Failed to fetch profile: \(error)")
            }
        }
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, layoutEnvironment) -> NSCollectionLayoutSection? in
            guard let self = self, sectionIndex < self.sections.count else { return nil }
            let section = self.sections[sectionIndex]
            
            switch section {
            case .banners:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(180)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 16, bottom: 8, trailing: 16)
                section.interGroupSpacing = 12
                return section
                
            case .categories:
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(80), heightDimension: .absolute(100)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(80), heightDimension: .absolute(100)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .continuous
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16)
                section.interGroupSpacing = 12
                return section
                
            case .products:
                let containerWidth = layoutEnvironment.container.contentSize.width
                let columns: CGFloat = (containerWidth / 3.0) > 100 ? 3 : 2
                
                let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0/columns), heightDimension: .estimated(220))
                let item = NSCollectionLayoutItem(layoutSize: itemSize)
                item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 12, trailing: 6)
                
                let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(220))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 20, trailing: 10)
                
                let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
                let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                section.boundarySupplementaryItems = [header]
                
                return section
            }
        }
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch sections[section] {
        case .banners(let banners): return banners.count
        case .categories(let categories): return categories.count
        case .products(_, let items): return items.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let section = sections[indexPath.section]
        
        switch section {
        case .banners(let banners):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.identifier, for: indexPath) as! BannerCell
            cell.configure(with: banners[indexPath.item])
            return cell
        case .categories(let categories):
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
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
            if case .products(let title, _) = sections[indexPath.section] {
                header.configure(with: title)
            }
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let section = sections[indexPath.section]
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

// MARK: - Banner Cell

final class BannerCell: UICollectionViewCell {
    static let identifier = "BannerCell"
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(imageView)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.roundCorners(radius: 12)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with banner: PromoBanner) {
        if let url = URL(string: banner.imageUrl) {
            imageView.kf.setImage(with: url, placeholder: UIImage(named: "banner_placeholder"))
        }
    }
}

// MARK: - Category Cell

final class CategoryCell: UICollectionViewCell {
    static let identifier = "CategoryCell"
    private let iconContainer = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        contentView.addSubview(titleLabel)
        
        iconContainer.backgroundColor = Brand.secondary
        iconContainer.layer.cornerRadius = 30
        iconContainer.clipsToBounds = true
        
        iconView.contentMode = .scaleAspectFill
        
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = Brand.Text.primary
        titleLabel.textAlignment = .center
        
        iconContainer.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(60)
        }
        
        iconView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconContainer.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func configure(with category: CatalogCategory) {
        titleLabel.text = category.name
        if let iconUrl = category.iconUrl, let url = URL(string: iconUrl) {
            iconView.kf.setImage(with: url)
        } else {
            iconView.image = nil
        }
    }
}

// MARK: - Section Header View

final class SectionHeaderView: UICollectionReusableView {
    static let identifier = "SectionHeaderView"
    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.font = Brand.Typography.subheader(size: 18)
        titleLabel.textColor = Brand.Text.primary
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    func configure(with title: String) {
        titleLabel.text = title
    }
}
