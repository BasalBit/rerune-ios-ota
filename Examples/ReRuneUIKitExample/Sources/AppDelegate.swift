import Combine
import UIKit
import ReRuneCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var cancellables = Set<AnyCancellable>()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        _ = launchOptions
        let publishId = Bundle.main.object(forInfoDictionaryKey: "RERUNE_OTA_PUBLISH_ID") as? String
            ?? ProcessInfo.processInfo.environment["RERUNE_OTA_PUBLISH_ID"]
            ?? "replace-with-ota-publish-id"

        ReRune.setup(otaPublishId: publishId)

        let controller = ViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UINavigationController(rootViewController: controller)
        window?.makeKeyAndVisible()

        ReRune.revisionPublisher
            .dropFirst()
            .sink { _ in controller.rebindStrings() }
            .store(in: &cancellables)

        return true
    }
}
