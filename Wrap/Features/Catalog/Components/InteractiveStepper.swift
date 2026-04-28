import UIKit

protocol InteractiveStepperDelegate: AnyObject {
    func stepper(_ stepper: InteractiveStepper, didUpdateValue value: Int)
}

final class InteractiveStepper: UIView {
    weak var delegate: InteractiveStepperDelegate?
    
    public private(set) var value: Int = 0 {
        didSet {
            if oldValue != value {
                updateUI()
            }
        }
    }
    
    private func notifyDelegate() {
        delegate?.stepper(self, didUpdateValue: value)
    }
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.backgroundColor = Brand.primary
        button.tintColor = .white
        button.roundCorners(radius: 8)
        return button
    }()
    
    private let containerView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .equalCentering
        stack.alignment = .center
        stack.backgroundColor = Brand.secondary
        stack.roundCorners(radius: 8)
        stack.isHidden = true
        return stack
    }()
    
    private let minusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "minus"), for: .normal)
        button.tintColor = Brand.primary
        return button
    }()
    
    private let plusButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = Brand.primary
        return button
    }()
    
    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = Brand.Typography.body(size: 14).withWeight(.bold)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        addSubview(addButton)
        addSubview(containerView)
        
        containerView.addArrangedSubview(minusButton)
        containerView.addArrangedSubview(valueLabel)
        containerView.addArrangedSubview(plusButton)
        
        addButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            addButton.topAnchor.constraint(equalTo: topAnchor),
            addButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            addButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            addButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            minusButton.widthAnchor.constraint(equalToConstant: 32),
            plusButton.widthAnchor.constraint(equalToConstant: 32)
        ])
        
        addButton.addTarget(self, action: #selector(didTapAdd), for: .touchUpInside)
        minusButton.addTarget(self, action: #selector(didTapMinus), for: .touchUpInside)
        plusButton.addTarget(self, action: #selector(didTapPlus), for: .touchUpInside)
    }
    
    @objc private func didTapAdd() {
        value = 1
        triggerHaptic(.medium)
        notifyDelegate()
    }
    
    @objc private func didTapMinus() {
        if value > 0 {
            value -= 1
            triggerHaptic(.light)
            notifyDelegate()
        }
    }
    
    @objc private func didTapPlus() {
        value += 1
        triggerHaptic(.medium)
        notifyDelegate()
    }
    
    private func updateUI() {
        let isActive = value > 0
        addButton.isHidden = isActive
        containerView.isHidden = !isActive
        valueLabel.text = "\(value)"
    }
    
    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    func setValue(_ newValue: Int) {
        self.value = newValue
    }
}

extension UIFont {
    func withWeight(_ weight: UIFont.Weight) -> UIFont {
        return UIFont.systemFont(ofSize: pointSize, weight: weight)
    }
}
