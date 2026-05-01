import UIKit

extension UIView {
    func startShimmering() {
        let light = UIColor(white: 0.9, alpha: 1.0).cgColor
        let dark = UIColor(white: 0.95, alpha: 1.0).cgColor
        
        let gradient = CAGradientLayer()
        gradient.colors = [light, dark, light]
        gradient.frame = CGRect(x: -self.bounds.width, y: 0, width: self.bounds.width * 3, height: self.bounds.height)
        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradient.locations = [0.0, 0.5, 1.0]
        self.layer.mask = gradient
        
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [0.0, 0.0, 0.25]
        animation.toValue = [0.75, 1.0, 1.0]
        animation.duration = 1.5
        animation.repeatCount = .infinity
        gradient.add(animation, forKey: "shimmer")
    }
    
    func stopShimmering() {
        self.layer.mask = nil
    }
}

class SkeletonView: UIView {
    private let shimmerLayer = CAGradientLayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = UIColor(white: 0.9, alpha: 1.0)
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    func start() {
        let light = UIColor(white: 0, alpha: 0.1).cgColor
        let dark = UIColor(white: 0, alpha: 0.15).cgColor
        
        shimmerLayer.colors = [light, dark, light]
        shimmerLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shimmerLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shimmerLayer.locations = [0.25, 0.5, 0.75]
        shimmerLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
        layer.addSublayer(shimmerLayer)
        
        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width * 2
        animation.duration = 1.5
        animation.repeatCount = .infinity
        shimmerLayer.add(animation, forKey: "shimmer")
    }
    
    func stop() {
        shimmerLayer.removeAllAnimations()
        shimmerLayer.removeFromSuperlayer()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        shimmerLayer.frame = CGRect(x: -bounds.width, y: 0, width: bounds.width * 3, height: bounds.height)
    }
}
