import UIKit
import Kingfisher
import SnapKit

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
        stopShimmering()
        if let url = URL(string: banner.imageUrl) {
            imageView.kf.setImage(with: url, placeholder: UIImage(named: "banner_placeholder"))
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        stopShimmering()
        imageView.image = nil
    }
}
