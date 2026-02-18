# ReRune SwiftUI Example

This sample demonstrates SwiftUI integration with `ReRuneCore` and `ReRuneSwiftUI` using a live OTA endpoint.

## Configure

1. Copy `Config/Example.xcconfig` to `Config/Local.xcconfig`.
2. Set `RERUNE_OTA_PUBLISH_ID` to a valid publish id.
3. In Xcode, assign `Local.xcconfig` to the app target build configuration.

## Run

- Open `ReRuneSwiftUIExample.xcodeproj`.
- Select scheme `ReRuneSwiftUIExample`.
- Run on an iOS 15+ simulator or device.

## Behavior

- App initializes ReRune in `App.init`.
- Strings are rendered with `reRuneString(...)`.
- `.reRuneObserveRevision()` refreshes views after revision updates.
