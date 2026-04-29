import UIKit

final class SharedElementNavigationDelegate: NSObject, UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> UIViewControllerAnimatedTransitioning? {
        
        let isSharedElementTransition = (fromVC is SharedElementProvider && toVC is SharedElementProvider)
        
        if isSharedElementTransition {
            return SharedElementAnimator(
                duration: 0.5,
                mode: operation == .push ? .present : .dismiss
            )
        }
        
        return nil
    }
}
