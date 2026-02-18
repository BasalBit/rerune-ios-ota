# Changelog

## 0.1.0

- Added initial iOS SDK implementation as Swift Package Manager modules: `ReRuneCore` and `ReRuneSwiftUI`.
- Added minimal public API centered on `ReRune.setup(...)`, `ReRune.checkForUpdates()`, `ReRune.revision`, and `reRuneString(...)`.
- Added OTA manifest and locale update flow with `X-OTA-Publish-Id`, fixed manifest endpoint, ETag support, cache-first startup, and fallback to bundled strings.
- Added UIKit and SwiftUI example app sources using live OTA endpoint configuration.
- Added unit tests for update flow, fallback behavior, and revision propagation.
