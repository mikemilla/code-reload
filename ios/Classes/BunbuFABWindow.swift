import UIKit

class BunbuFABWindow: UIWindow {
    private var fabButton: UIButton!
    private var onTap: (() -> Void)?
    private var panOrigin: CGPoint = .zero

    init(onTap: @escaping () -> Void) {
        self.onTap = onTap
        super.init(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        setup()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setup() {
        windowLevel = .normal + 1
        backgroundColor = .clear
        isHidden = false

        let rootVC = UIViewController()
        rootVC.view.backgroundColor = .clear
        rootViewController = rootVC

        fabButton = UIButton(type: .custom)
        fabButton.frame = CGRect(x: 0, y: 0, width: 56, height: 56)
        fabButton.layer.cornerRadius = 28
        fabButton.clipsToBounds = true
        fabButton.addTarget(self, action: #selector(tapped), for: .touchUpInside)

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.42, green: 0.39, blue: 1.0, alpha: 1.0).cgColor,
            UIColor(red: 0.61, green: 0.35, blue: 0.71, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        gradient.frame = fabButton.bounds
        gradient.cornerRadius = 28
        fabButton.layer.insertSublayer(gradient, at: 0)

        let icon = UIImageView(image: UIImage(systemName: "sparkles"))
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.frame = CGRect(x: 16, y: 16, width: 24, height: 24)
        fabButton.addSubview(icon)

        fabButton.layer.shadowColor = UIColor(red: 0.42, green: 0.39, blue: 1.0, alpha: 0.4).cgColor
        fabButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        fabButton.layer.shadowRadius = 16
        fabButton.layer.shadowOpacity = 1.0
        fabButton.layer.masksToBounds = false

        rootVC.view.addSubview(fabButton)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(dragged(_:)))
        fabButton.addGestureRecognizer(pan)

        positionDefault()
    }

    private func positionDefault() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let screenBounds = scene.coordinateSpace.bounds
        let x = screenBounds.width - 56 - 16
        let y = screenBounds.height - 56 - 80
        frame = CGRect(x: x, y: y, width: 56, height: 56)
    }

    @objc private func tapped() {
        onTap?()
    }

    @objc private func dragged(_ gesture: UIPanGestureRecognizer) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        let screenBounds = scene.coordinateSpace.bounds

        switch gesture.state {
        case .began:
            panOrigin = frame.origin
        case .changed:
            let translation = gesture.translation(in: nil)
            var newX = panOrigin.x + translation.x
            var newY = panOrigin.y + translation.y
            newX = max(0, min(newX, screenBounds.width - 56))
            newY = max(0, min(newY, screenBounds.height - 56))
            frame.origin = CGPoint(x: newX, y: newY)
        default:
            break
        }
    }

    func showFAB() {
        isHidden = false
    }

    func hideFAB() {
        isHidden = true
    }
}
