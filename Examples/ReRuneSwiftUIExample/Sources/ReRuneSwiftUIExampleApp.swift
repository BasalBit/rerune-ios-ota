import SwiftUI
import ReRuneCore
import ReRuneSwiftUI

@main
struct ReRuneSwiftUIExampleApp: App {
    init() {
        let publishId = Bundle.main.object(forInfoDictionaryKey: "RERUNE_OTA_PUBLISH_ID") as? String
            ?? ProcessInfo.processInfo.environment["RERUNE_OTA_PUBLISH_ID"]
            ?? "replace-with-ota-publish-id"
        ReRune.setup(otaPublishId: publishId)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .reRuneObserveRevision()
        }
    }
}
