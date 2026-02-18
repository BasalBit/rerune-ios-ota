# rerune-ios-ota

iOS over-the-air localization SDK for ReRune.

## Packages

- `ReRuneCore`: core OTA fetch/cache/lookup APIs.
- `ReRuneSwiftUI`: tiny SwiftUI revision observer helper.

## Requirements

- Swift Package Manager
- iOS 15+

## Install (SPM)

Add this repository URL in Xcode package dependencies and import:

```swift
import ReRuneCore
import ReRuneSwiftUI
```

## UIKit quick start

```swift
import ReRuneCore

ReRune.setup(otaPublishId: "replace-with-ota-publish-id")

titleLabel.text = reRuneString("home_title")

ReRune.revisionPublisher
    .dropFirst()
    .sink { [weak self] _ in self?.rebindStrings() }
    .store(in: &cancellables)
```

## SwiftUI quick start

```swift
import ReRuneCore
import ReRuneSwiftUI

@main
struct ExampleApp: App {
    init() {
        ReRune.setup(otaPublishId: "replace-with-ota-publish-id")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .reRuneObserveRevision()
        }
    }
}
```

## Notes

- SDK is opt-in and does not swizzle or globally intercept iOS localization APIs.
- API auth is `otaPublishId` only.
- Manifest endpoint is fixed by SDK.

## Example apps

- `Examples/ReRuneUIKitExample`
- `Examples/ReRuneSwiftUIExample`

Both examples are configured for live endpoint usage with `RERUNE_OTA_PUBLISH_ID`.
