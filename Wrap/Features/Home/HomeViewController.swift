import UIKit
import Kingfisher
import SnapKit

final class HomeViewController: UIViewController {
    
    weak var coordinator: MainCoordinator?
    
    private enum SectionType: String {
        case banners
        case categories
        case standard
        case flash_sale
        case personalized
    }
    
    private var feed: HomeFeedData?
    private var user: UserData?
    
    private let headerView = HomeHeaderView()
    
    private lazy var collectionView: UICollectionView = {
        let layout = createLayout()
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .systemBackground
        cv.register(ProductCardView.self, forCellWithReuseIdentifier: ProductCardView.identifier)
        cv.register(BannerCell.self, forCellWithReuseIdentifier: BannerCell.identifier)
        cv.register(CategoryCell.self, forCellWithReuseIdentifier: CategoryCell.identifier)
        cv.register(SectionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: SectionHeaderView.identifier)
        return cv
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        fetchData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        view.addSubview(headerView)
        view.addSubview(collectionView)
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    private func fetchData() {
        Task {
            do {
                let fetchedFeed = try await self.performFetchHome()
                let fetchedUserData = try await self.performFetchProfile()
                
                self.feed = fetchedFeed
                self.user = fetchedUserData
                
                headerView.configure(with: fetchedUserData)
                self.collectionView.reloadData()
            } catch {
                print("Failed to fetch home data: \(error)")
            }
        }
    }
    
    nonisolated private func performFetchHome() async throws -> HomeFeedData {
        try await NetworkManager.shared.request(endpoint: "/catalog/home")
    }
    
    nonisolated private func performFetchProfile() async throws -> UserData {
        try await NetworkManager.shared.request(endpoint: "/user/profile")
    }
    
    private func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { [weak self] (sectionIndex, _) -> NSCollectionLayoutSection? in
            guard let self = self, let feed = self.feed else { return nil }
            
            if sectionIndex == 0 { // Banners
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.92), heightDimension: .absolute(160)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.orthogonalScrollingBehavior = .groupPagingCentered
                section.interGroupSpacing = 12
                section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0)
                return section
            } else if sectionIndex == 1 { // Categories
                let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25), heightDimension: .absolute(100)))
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100)), subitems: [item])
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 16, trailing: 16)
                return section
            } else { // Dynamic Product Sections
                let feedSection = feed.sections[sectionIndex - 2]
                
                if feedSection.type == "personalized" {
                    // Horizontal Scroll for "Favorit Kamu"
                    let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalHeight(1)))
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .absolute(160), heightDimension: .absolute(240)), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.orthogonalScrollingBehavior = .continuous
                    section.interGroupSpacing = 12
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 24, trailing: 16)
                    
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    section.boundarySupplementaryItems = [header]
                    return section
                } else {
                    // Vertical 2-column Grid for others
                    let item = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .estimated(240)))
                    item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 6, bottom: 16, trailing: 6)
                    let group = NSCollectionLayoutGroup.horizontal(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .estimated(240)), subitems: [item])
                    let section = NSCollectionLayoutSection(group: group)
                    section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 10, bottom: 16, trailing: 10)
                    
                    let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
                    let header = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize, elementKind: UICollectionView.elementKindSectionHeader, alignment: .top)
                    section.boundarySupplementaryItems = [header]
                    
                    return section
                }
            }
        }
    }
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let feed = feed else { return 3 } // Dummy sections for skeleton
        return 2 + feed.sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let feed = feed else {
            if section == 0 { return 1 } // 1 Banner skeleton
            if section == 1 { return 4 } // 4 Category skeletons
            return 4 // 4 Product skeletons
        }
        if section == 0 { return feed.banners.count }
        if section == 1 { return feed.categories.count }
        return feed.sections[section - 2].items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if feed == nil {
            if indexPath.section == 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.identifier, for: indexPath) as! BannerCell
                cell.contentView.startShimmering()
                return cell
            } else if indexPath.section == 1 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
                cell.contentView.startShimmering()
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
                cell.contentView.startShimmering()
                return cell
            }
        }
        
        guard let feed = feed else { return UICollectionViewCell() }
        
        if indexPath.section == 0 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BannerCell.identifier, for: indexPath) as! BannerCell
            cell.contentView.stopShimmering()
            cell.configure(with: feed.banners[indexPath.item])
            return cell
        } else if indexPath.section == 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CategoryCell.identifier, for: indexPath) as! CategoryCell
            cell.contentView.stopShimmering()
            cell.configure(with: feed.categories[indexPath.item])
            return cell
        } else {
            let sectionData = feed.sections[indexPath.section - 2]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ProductCardView.identifier, for: indexPath) as! ProductCardView
            cell.contentView.stopShimmering()
            cell.configure(with: sectionData.items[indexPath.item])
            cell.delegate = self
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SectionHeaderView.identifier, for: indexPath) as! SectionHeaderView
            if indexPath.section >= 2 {
                header.titleLabel.text = feed?.sections[indexPath.section - 2].title
            }
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let feed = feed else { return }
        
        if indexPath.section == 1 {
            let category = feed.categories[indexPath.item]
            coordinator?.showCatalogCategory(category: category)
        } else if indexPath.section >= 2 {
            let product = feed.sections[indexPath.section - 2].items[indexPath.item]
            coordinator?.showProductDetail(productId: product.id)
        }
    }
}

extension HomeViewController: ProductCardDelegate {
    func productCard(_ cell: ProductCardView, didUpdateQuantity quantity: Int, for product: Product) {
        guard let firstVariant = product.variants?.first else { return }
        let price = firstVariant.priceOverride ?? product.basePrice
        
        if quantity > 0 && CartManager.shared.items.first(where: { $0.variantId == firstVariant.id }) == nil {
            CartManager.shared.add(variantId: firstVariant.id, name: product.name, price: price, quantity: quantity)
        } else {
            CartManager.shared.setQuantity(variantId: firstVariant.id, quantity: quantity)
        }
    }
}

// MARK: - Custom Views (Header, Cells, etc.)

final class HomeHeaderView: UIView {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 14)
        label.textColor = .secondaryLabel
        label.text = "Halo,"
        return label
    }()
    
    private let addressLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.subheader(size: 16)
        label.textColor = .black
        label.numberOfLines = 1
        label.text = "Atur alamat..."
        return label
    }()
    
    private let searchBar: UISearchBar = {
        let sb = UISearchBar()
        sb.placeholder = "Cari Indomie, Telur, atau Susu..."
        sb.searchBarStyle = .minimal
        return sb
    }()
    
    init() {
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        backgroundColor = .systemBackground
        addSubview(nameLabel)
        addSubview(addressLabel)
        addSubview(searchBar)
        
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.equalToSuperview().offset(20)
        }
        
        addressLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
        }
        
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(addressLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    func configure(with user: UserData) {
        nameLabel.text = "Hello, \(user.fullName)"
        addressLabel.text = user.fullAddress ?? "Set your address"
    }
}

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
            make.edges.equalToSuperview().inset(4)
        }
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(with banner: PromoBanner) {
        if let url = URL(string: banner.imageUrl) { imageView.kf.setImage(with: url) }
    }
}

final class CategoryCell: UICollectionViewCell {
    static let identifier = "CategoryCell"
    private let imageView = UIImageView()
    private let label = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        let stack = UIStackView(arrangedSubviews: [imageView, label])
        stack.axis = .vertical; stack.alignment = .center; stack.spacing = 8
        contentView.addSubview(stack)
        stack.snp.makeConstraints { make in make.edges.equalToSuperview().inset(4) }
        imageView.snp.makeConstraints { make in make.size.equalTo(52) }
        imageView.backgroundColor = Brand.secondary; imageView.roundCorners(radius: 26)
        label.font = Brand.Typography.body(size: 11); label.textAlignment = .center; label.numberOfLines = 2
    }
    required init?(coder: NSCoder) { fatalError() }
    func configure(with category: CatalogCategory) {
        label.text = category.name
        if let iconUrl = category.iconUrl, let url = URL(string: iconUrl) {
            imageView.kf.setImage(with: url)
            imageView.contentMode = .scaleAspectFill
        }
    }
}

final class SectionHeaderView: UICollectionReusableView {
    static let identifier = "SectionHeaderView"
    let titleLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.font = Brand.Typography.subheader(size: 18)
        titleLabel.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(4); make.centerY.equalToSuperview()
        }
    }
    required init?(coder: NSCoder) { fatalError() }
}
