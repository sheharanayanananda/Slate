import SwiftUI

enum SwipeDirection {
    case right
    case left
}

struct DirectionalSwipeGestureModifier: ViewModifier {
    var isEnabled: Bool
    var direction: SwipeDirection
    var onDragChanged: (CGFloat) -> Void
    var onDragEnded: (CGFloat, CGFloat) -> Void

    func body(content: Content) -> some View {
        content
            .background(
                DirectionalSwipeGestureControllerRepresentable(
                    isEnabled: isEnabled,
                    direction: direction,
                    onDragChanged: onDragChanged,
                    onDragEnded: onDragEnded
                )
            )
    }
}

struct DirectionalSwipeGestureControllerRepresentable: UIViewControllerRepresentable {
    var isEnabled: Bool
    var direction: SwipeDirection
    var onDragChanged: (CGFloat) -> Void
    var onDragEnded: (CGFloat, CGFloat) -> Void

    func makeUIViewController(context: Context) -> DirectionalSwipeGestureViewController {
        let vc = DirectionalSwipeGestureViewController()
        vc.onDragChanged = onDragChanged
        vc.onDragEnded = onDragEnded
        vc.isEnabled = isEnabled
        vc.direction = direction
        return vc
    }

    func updateUIViewController(_ uiViewController: DirectionalSwipeGestureViewController, context: Context) {
        uiViewController.onDragChanged = onDragChanged
        uiViewController.onDragEnded = onDragEnded
        uiViewController.isEnabled = isEnabled
        uiViewController.direction = direction
    }
}

class DirectionalSwipeGestureViewController: UIViewController, UIGestureRecognizerDelegate {
    var isEnabled: Bool = false
    var direction: SwipeDirection = .right
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
        
        let isHorizontal = abs(velocity.x) > abs(velocity.y) * 1.5
        guard isHorizontal else { return false }
        
        switch direction {
        case .right:
            return velocity.x > 0
        case .left:
            return velocity.x < 0
        }
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false 
    }
}

extension View {
    func onSwipeRightToOpen(isEnabled: Bool, onDragChanged: @escaping (CGFloat) -> Void, onDragEnded: @escaping (CGFloat, CGFloat) -> Void) -> some View {
        self.modifier(DirectionalSwipeGestureModifier(isEnabled: isEnabled, direction: .right, onDragChanged: onDragChanged, onDragEnded: onDragEnded))
    }
    
    func onSwipeLeftToClose(isEnabled: Bool, onDragChanged: @escaping (CGFloat) -> Void, onDragEnded: @escaping (CGFloat, CGFloat) -> Void) -> some View {
        self.modifier(DirectionalSwipeGestureModifier(isEnabled: isEnabled, direction: .left, onDragChanged: onDragChanged, onDragEnded: onDragEnded))
    }
}
