import UIKit
import Kingfisher
import SnapKit
import SkeletonView

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
        contentView.isSkeletonable = true
        contentView.addSubview(iconContainer)
        iconContainer.addSubview(iconView)
        contentView.addSubview(titleLabel)
        
        iconContainer.backgroundColor = Brand.secondary
        iconContainer.layer.cornerRadius = 30
        iconContainer.clipsToBounds = true
        iconContainer.isSkeletonable = true
        iconContainer.skeletonCornerRadius = 30
        
        iconView.contentMode = .scaleAspectFill
        
        titleLabel.font = .systemFont(ofSize: 12, weight: .medium)
        titleLabel.textColor = Brand.Text.primary
        titleLabel.textAlignment = .center
        titleLabel.isSkeletonable = true
        titleLabel.linesCornerRadius = 4
        
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
        hideSkeleton()
        titleLabel.text = category.name
        if let iconUrl = category.iconUrl, let url = URL(string: iconUrl) {
            iconView.kf.setImage(with: url)
        } else {
            iconView.image = nil
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        hideSkeleton()
        titleLabel.text = nil
        iconView.image = nil
    }
}
