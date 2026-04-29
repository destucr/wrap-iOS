import UIKit

enum Brand {
    static let primary = UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1.0) // Wrap Emerald
    static let secondary = UIColor.systemGray6
    static let accent = UIColor.systemOrange
    
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
    }
}

extension UIView {
    func applyShadow() {
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowRadius = 6
        self.layer.shadowOpacity = 0.1
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
        let formattedString = formatter.string(from: NSNumber(value: self)) ?? "\(Int(self))"
        return "Rp\(formattedString)"
    }
}
