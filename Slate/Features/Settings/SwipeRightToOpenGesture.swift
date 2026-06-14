import SwiftUI

struct SwipeRightGestureModifier: ViewModifier {
    var isEnabled: Bool
    var onDragChanged: (CGFloat) -> Void
    var onDragEnded: (CGFloat, CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                SwipeRightGestureControllerRepresentable(
                    isEnabled: isEnabled,
                    onDragChanged: onDragChanged,
                    onDragEnded: onDragEnded
                )
            )
    }
}

struct SwipeRightGestureControllerRepresentable: UIViewControllerRepresentable {
    var isEnabled: Bool
    var onDragChanged: (CGFloat) -> Void
    var onDragEnded: (CGFloat, CGFloat) -> Void

    func makeUIViewController(context: Context) -> SwipeRightGestureViewController {
        let vc = SwipeRightGestureViewController()
        vc.onDragChanged = onDragChanged
        vc.onDragEnded = onDragEnded
        vc.isEnabled = isEnabled
        return vc
    }

    func updateUIViewController(_ uiViewController: SwipeRightGestureViewController, context: Context) {
        uiViewController.onDragChanged = onDragChanged
        uiViewController.onDragEnded = onDragEnded
        uiViewController.isEnabled = isEnabled
    }
}

class SwipeRightGestureViewController: UIViewController, UIGestureRecognizerDelegate {
    var isEnabled: Bool = false
    var onDragChanged: ((CGFloat) -> Void)?
    var onDragEnded: ((CGFloat, CGFloat) -> Void)?
    
    private var panGesture: UIPanGestureRecognizer!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
    }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        if let parentView = parent?.view {
            parentView.addGestureRecognizer(panGesture)
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isEnabled else { return }
        let translation = gesture.translation(in: gesture.view)
        let velocity = gesture.velocity(in: gesture.view)
        
        switch gesture.state {
        case .changed:
            onDragChanged?(translation.x)
        case .ended, .cancelled:
            onDragEnded?(translation.x, velocity.x)
        default:
            break
        }
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled else { return false }
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer else { return false }
        let velocity = pan.velocity(in: pan.view)
        
        // Only trigger on left-to-right horizontal swipe
        return velocity.x > 0 && abs(velocity.x) > abs(velocity.y) * 1.5
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false 
    }
}

extension View {
    func onSwipeRightToOpen(isEnabled: Bool, onDragChanged: @escaping (CGFloat) -> Void, onDragEnded: @escaping (CGFloat, CGFloat) -> Void) -> some View {
        self.modifier(SwipeRightGestureModifier(isEnabled: isEnabled, onDragChanged: onDragChanged, onDragEnded: onDragEnded))
    }
}
