import UIKit

protocol SharedElementProvider {
    var sharedImageView: UIImageView? { get }
    var sharedTitleLabel: UILabel? { get }
}

final class SharedElementAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    enum TransitionMode {
        case present, dismiss
    }
    
    let duration: TimeInterval
    let mode: TransitionMode
    
    init(duration: TimeInterval = 0.5, mode: TransitionMode) {
        self.duration = duration
        self.mode = mode
        super.init()
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return duration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromVC = transitionContext.viewController(forKey: .from),
              let toVC = transitionContext.viewController(forKey: .to),
              let fromView = fromVC.view,
              let toView = toVC.view else {
            transitionContext.completeTransition(false)
            return
        }
        
        let containerView = transitionContext.containerView
        
        let providerSource = (mode == .present ? fromVC : toVC) as? SharedElementProvider
        let providerDest = (mode == .present ? toVC : fromVC) as? SharedElementProvider
        
        // Find the actual VCs if they are embedded in NavigationControllers (which they might be in our TabBar setup)
        // For simplicity, we assume the provider is directly the view controller pushing/popping.
        
        guard let sourceImageView = providerSource?.sharedImageView,
              let destImageView = providerDest?.sharedImageView else {
            
            // Fallback to standard cross dissolve if no shared elements are found
            if mode == .present {
                containerView.addSubview(toView)
                toView.alpha = 0
                UIView.animate(withDuration: duration, animations: {
                    toView.alpha = 1
                }) { _ in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            } else {
                containerView.insertSubview(toView, belowSubview: fromView)
                UIView.animate(withDuration: duration, animations: {
                    fromView.alpha = 0
                }) { _ in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                }
            }
            return
        }
        
        // 1. Setup Container
        if mode == .present {
            containerView.addSubview(toView)
            toView.layoutIfNeeded()
        } else {
            containerView.insertSubview(toView, belowSubview: fromView)
        }
        
        // 2. Create snapshots/copies for animation
        let snapshotImageView = UIImageView(image: sourceImageView.image)
        snapshotImageView.contentMode = sourceImageView.contentMode
        snapshotImageView.clipsToBounds = sourceImageView.clipsToBounds
        snapshotImageView.layer.cornerRadius = sourceImageView.layer.cornerRadius
        
        // Convert frames to container coordinates
        let startImageFrame = sourceImageView.convert(sourceImageView.bounds, to: containerView)
        let endImageFrame = destImageView.convert(destImageView.bounds, to: containerView)
        
        snapshotImageView.frame = mode == .present ? startImageFrame : endImageFrame
        
        containerView.addSubview(snapshotImageView)
        
        // 3. Create title snapshot if available
        var snapshotTitleLabel: UILabel?
        var startTitleFrame: CGRect = .zero
        var endTitleFrame: CGRect = .zero
        
        if let sourceTitle = providerSource?.sharedTitleLabel, let destTitle = providerDest?.sharedTitleLabel {
            snapshotTitleLabel = UILabel()
            snapshotTitleLabel?.text = sourceTitle.text
            snapshotTitleLabel?.font = sourceTitle.font
            snapshotTitleLabel?.textColor = sourceTitle.textColor
            snapshotTitleLabel?.numberOfLines = sourceTitle.numberOfLines
            
            startTitleFrame = sourceTitle.convert(sourceTitle.bounds, to: containerView)
            endTitleFrame = destTitle.convert(destTitle.bounds, to: containerView)
            
            snapshotTitleLabel?.frame = mode == .present ? startTitleFrame : endTitleFrame
            if let st = snapshotTitleLabel { containerView.addSubview(st) }
        }
        
        // 4. Hide originals
        sourceImageView.isHidden = true
        destImageView.isHidden = true
        providerSource?.sharedTitleLabel?.isHidden = true
        providerDest?.sharedTitleLabel?.isHidden = true
        
        if mode == .present {
            toView.alpha = 0
        }
        
        // 5. Animate
        let animator = UIViewPropertyAnimator(duration: duration, dampingRatio: 0.8) {
            if self.mode == .present {
                toView.alpha = 1
                snapshotImageView.frame = endImageFrame
                snapshotImageView.layer.cornerRadius = destImageView.layer.cornerRadius
                if let st = snapshotTitleLabel {
                    st.frame = endTitleFrame
                    st.font = providerDest?.sharedTitleLabel?.font
                }
            } else {
                fromView.alpha = 0
                snapshotImageView.frame = startImageFrame
                snapshotImageView.layer.cornerRadius = sourceImageView.layer.cornerRadius
                if let st = snapshotTitleLabel {
                    st.frame = startTitleFrame
                    st.font = providerSource?.sharedTitleLabel?.font
                }
            }
        }
        
        animator.addCompletion { _ in
            sourceImageView.isHidden = false
            destImageView.isHidden = false
            providerSource?.sharedTitleLabel?.isHidden = false
            providerDest?.sharedTitleLabel?.isHidden = false
            
            snapshotImageView.removeFromSuperview()
            snapshotTitleLabel?.removeFromSuperview()
            
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
        
        animator.startAnimation()
    }
}
