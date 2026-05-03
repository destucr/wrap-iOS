import UIKit
import SnapKit

final class DynamicETABanner: UIView {
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.tintColor = .white
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textColor = .white
        return label
    }()
    
    private let etaLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white.withAlphaComponent(0.9)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupUI() {
        layer.cornerRadius = 12
        clipsToBounds = true
        
        addSubview(iconImageView)
        addSubview(titleLabel)
        addSubview(etaLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(8)
            make.top.equalToSuperview().offset(8)
        }
        
        etaLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.bottom.equalToSuperview().offset(-8)
        }
    }
    
    func configure(with info: ETAInfo) {
        backgroundColor = info.state.color
        titleLabel.text = info.message
        
        if info.state == .offline {
            iconImageView.image = UIImage(systemName: "moon.zzz.fill")
            etaLabel.text = "Cek kembali nanti"
        } else {
            iconImageView.image = UIImage(systemName: "timer")
            etaLabel.text = "Estimasi Sampai: \(info.etaMins) Menit"
        }
        
        // Pulse animation for high load
        if info.state == .overloaded {
            self.alpha = 1.0
            UIView.animate(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction], animations: {
                self.alpha = 0.8
            }, completion: nil)
        } else {
            self.layer.removeAllAnimations()
            self.alpha = 1.0
        }
    }
}
