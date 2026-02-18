import UIKit
import ReRuneCore

final class ViewController: UIViewController {
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let checkButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        layoutViews()
        rebindStrings()
    }

    func rebindStrings() {
        navigationItem.title = reRuneString("home_title")
        titleLabel.text = reRuneString("home_title")
        subtitleLabel.text = reRuneString("home_subtitle")
        checkButton.setTitle(reRuneString("refresh_button"), for: .normal)
    }

    @objc
    private func checkForUpdates() {
        Task {
            _ = await ReRune.checkForUpdates()
        }
    }

    private func layoutViews() {
        titleLabel.font = .preferredFont(forTextStyle: .title1)
        subtitleLabel.font = .preferredFont(forTextStyle: .body)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 0

        checkButton.addTarget(self, action: #selector(checkForUpdates), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, checkButton])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
