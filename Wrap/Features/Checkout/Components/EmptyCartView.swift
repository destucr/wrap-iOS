import UIKit
import SnapKit

final class EmptyCartView: UIView {

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true

        // ADD THIS LINE:
        sv.contentInsetAdjustmentBehavior = .always

        return sv
    }()

    private let contentView = UIView()

    private let iconView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "cart.badge.minus"))
        iv.tintColor = .systemGray4
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Keranjang kamu masih kosong"
        label.font = Brand.Typography.header(size: 20)
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Ayo isi dengan produk-produk pilihan terbaik untuk kebutuhan harianmu."
        label.font = Brand.Typography.body(size: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()

    let shopButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Mulai Belanja", for: .normal)
        button.backgroundColor = Brand.primary
        button.setTitleColor(.white, for: .normal)
        button.roundCorners(radius: 12)
        button.titleLabel?.font = Brand.Typography.subheader(size: 16)
        return button
    }()

    private let recommendationLabel: UILabel = {
        let label = UILabel()
        label.text = "Rekomendasi Untukmu"
        label.font = Brand.Typography.subheader(size: 18)
        return label
    }()

    lazy var recommendationsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 160, height: 240)
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)

        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(ProductCardView.self, forCellWithReuseIdentifier: ProductCardView.identifier)
        return cv
    }()

    init() {
        super.init(frame: .zero)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        // 2. Setup ScrollView Hierarchy
        addSubview(scrollView)
        scrollView.addSubview(contentView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview() // Lock horizontal scrolling
        }

        // 3. Add all components to contentView instead of self
        [iconView, titleLabel, subtitleLabel, shopButton, recommendationLabel, recommendationsCollectionView].forEach {
            contentView.addSubview($0)
        }

        iconView.snp.makeConstraints { make in
            // This ensures it starts below the status bar/notch
            // even though the navigation bar is hidden
            make.top.equalTo(safeAreaLayoutGuide.snp.top).offset(40)
            make.centerX.equalToSuperview()
            make.size.equalTo(100)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(24)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(40)
        }

        shopButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(24)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(48)
        }

        recommendationLabel.snp.makeConstraints { make in
            make.top.equalTo(shopButton.snp.bottom).offset(60)
            make.leading.equalToSuperview().offset(20)
        }

        recommendationsCollectionView.snp.makeConstraints { make in
            make.top.equalTo(recommendationLabel.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(250)
            // 4. IMPORTANT: Pin the last element to the bottom of the contentView
            make.bottom.equalToSuperview().offset(-40)
        }
    }
}
