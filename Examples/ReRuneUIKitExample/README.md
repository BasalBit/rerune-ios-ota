# ReRune UIKit Example

This sample demonstrates UIKit integration with `ReRuneCore` using a live OTA endpoint.

## Configure

1. Copy `Config/Example.xcconfig` to `Config/Local.xcconfig`.
2. Set `RERUNE_OTA_PUBLISH_ID` to a valid publish id.
3. In Xcode, assign `Local.xcconfig` to the app target build configuration.

## Behavior

- App calls `ReRune.setup(...)` on launch.
- UI strings are read with `reRuneString(...)`.
- Visible labels are rebound when `ReRune.revisionPublisher` emits.
