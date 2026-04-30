import UIKit

enum Brand {
    static let primary = UIColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0) // #34C759 - Success Green
    static let secondary = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.0) // #F2F2F7 - Page Background
    static let accent = UIColor.systemOrange
    
    enum Text {
        static let primary = UIColor(red: 0.11, green: 0.11, blue: 0.12, alpha: 1.0) // #1C1C1E
        static let secondary = UIColor(red: 0.56, green: 0.56, blue: 0.58, alpha: 1.0) // #8E8E93
    }
    
    enum Typography {
        static func header(size: CGFloat = 24) -> UIFont {
            return .systemFont(ofSize: size, weight: .bold)
        }
        static func subheader(size: CGFloat = 18) -> UIFont {
            return .systemFont(ofSize: size, weight: .semibold)
        }
        static func body(size: CGFloat = 16) -> UIFont {
            return .systemFont(ofSize: size, weight: .regular)
        }
        static func caption(size: CGFloat = 12) -> UIFont {
            return .systemFont(ofSize: size, weight: .thin)
        }

        // Redesign Specifics
        static func productName() -> UIFont {
            return .systemFont(ofSize: 14, weight: .semibold)
        }
        static func unitLabel() -> UIFont {
            return .systemFont(ofSize: 12, weight: .regular)
        }
        static func price() -> UIFont {
            return .systemFont(ofSize: 14, weight: .thin)
        }
    }
}

extension UIView {
    func applyShadow(opacity: Float = 0.08, radius: CGFloat = 8, offset: CGSize = CGSize(width: 0, height: 2)) {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowRadius = radius
        self.layer.shadowOpacity = opacity
        self.layer.masksToBounds = false
    }
    
    func applyCardShadow() {
        applyShadow(opacity: 0.08, radius: 8)
    }
    
    func roundCorners(radius: CGFloat = 12) {
        self.layer.cornerRadius = radius
        self.layer.masksToBounds = true
    }
}

extension Double {
    var formattedIDR: String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.maximumFractionDigits = 0
        let formattedString = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "Rp\(formattedString)"
    }
}
