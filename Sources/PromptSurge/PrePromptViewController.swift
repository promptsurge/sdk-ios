import UIKit
import StoreKit

final class PrePromptViewController: UIViewController {
    private let promptResponse: PromptResponse
    private let onAccept: () -> Void
    private let onDismiss: () -> Void

    private let cardView = UIView()
    private let headerImageView = UIImageView()
    private let titleLabel = UILabel()
    private let bodyLabel = UILabel()
    private let positiveButton = UIButton(type: .system)
    private let negativeButton = UIButton(type: .system)

    private var imageHeightConstraint: NSLayoutConstraint?

    init(promptResponse: PromptResponse, onAccept: @escaping () -> Void, onDismiss: @escaping () -> Void) {
        self.promptResponse = promptResponse
        self.onAccept = onAccept
        self.onDismiss = onDismiss
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackground()
        setupCard()
    }

    private func setupBackground() {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapDismiss))
        view.addGestureRecognizer(tap)
    }

    private func setupCard() {
        let theme = promptResponse.theme
        let text = promptResponse.text

        cardView.backgroundColor = color(theme?.backgroundColor) ?? .systemBackground
        cardView.layer.cornerRadius = theme?.borderRadius.map { CGFloat($0) } ?? 16
        cardView.layer.masksToBounds = true
        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.isUserInteractionEnabled = true
        view.addSubview(cardView)

        // Header image view — initially zero height, expands after image loads
        headerImageView.contentMode = .scaleAspectFill
        headerImageView.clipsToBounds = true
        headerImageView.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(headerImageView)

        let imageHeight = headerImageView.heightAnchor.constraint(equalToConstant: 0)
        imageHeight.isActive = true
        imageHeightConstraint = imageHeight

        let textColor = color(theme?.textColor) ?? UIColor.label

        titleLabel.text = text.title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textColor = textColor
        titleLabel.numberOfLines = 0
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        bodyLabel.text = text.body
        bodyLabel.font = .systemFont(ofSize: 15)
        bodyLabel.textColor = textColor
        bodyLabel.numberOfLines = 0
        bodyLabel.textAlignment = .center
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        styleButton(positiveButton,
                    title: text.positiveButton,
                    tintColor: color(theme?.positiveButtonColor) ?? .systemBlue,
                    weight: .semibold)
        positiveButton.addTarget(self, action: #selector(didTapAccept), for: .touchUpInside)

        styleButton(negativeButton,
                    title: text.negativeButton,
                    tintColor: color(theme?.negativeButtonColor) ?? .systemGray,
                    weight: .regular)
        negativeButton.addTarget(self, action: #selector(didTapDismiss), for: .touchUpInside)

        // Negative (dismiss) on the left, positive (accept) on the right.
        let buttonStack = UIStackView(arrangedSubviews: [negativeButton, positiveButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 12
        buttonStack.translatesAutoresizingMaskIntoConstraints = false

        [titleLabel, bodyLabel, buttonStack].forEach { cardView.addSubview($0) }

        NSLayoutConstraint.activate([
            cardView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cardView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            cardView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),

            headerImageView.topAnchor.constraint(equalTo: cardView.topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor),
            headerImageView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor),

            titleLabel.topAnchor.constraint(equalTo: headerImageView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            bodyLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            bodyLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 24),
            buttonStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
        ])

        // Load header image asynchronously if URL provided
        if let urlString = promptResponse.imageUrl, let url = URL(string: urlString) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let image = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.headerImageView.image = image
                    // Set image height proportional to width (max 160 pt)
                    let cardWidth = self.view.bounds.width * 0.85
                    let ratio = image.size.height / image.size.width
                    let targetHeight = min(cardWidth * ratio, 160)
                    self.imageHeightConstraint?.constant = targetHeight
                    UIView.animate(withDuration: 0.2) {
                        self.view.layoutIfNeeded()
                    }
                }
            }.resume()
        }
    }

    @objc private func didTapAccept() {
        dismiss(animated: true) {
            self.requestStoreReview()
            self.onAccept()
        }
    }

    @objc private func didTapDismiss() {
        dismiss(animated: true, completion: onDismiss)
    }

    private func requestStoreReview() {
        guard let scene = view.window?.windowScene else { return }
        SKStoreReviewController.requestReview(in: scene)
    }

    private func styleButton(_ button: UIButton, title: String, tintColor: UIColor, weight: UIFont.Weight) {
        button.setTitle(title, for: .normal)
        button.tintColor = tintColor
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: weight)
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = tintColor.withAlphaComponent(0.3).cgColor
        button.translatesAutoresizingMaskIntoConstraints = false
    }

    private func color(_ hex: String?) -> UIColor? {
        guard let hex = hex else { return nil }
        let trimmed = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        guard trimmed.count == 6, let value = UInt64(trimmed, radix: 16) else { return nil }
        return UIColor(
            red: CGFloat((value >> 16) & 0xFF) / 255,
            green: CGFloat((value >> 8) & 0xFF) / 255,
            blue: CGFloat(value & 0xFF) / 255,
            alpha: 1
        )
    }
}
