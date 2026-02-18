# ReRune iOS SDK Spec (v1)

## Baseline from current product (this repo)

The current product is a lean Android SDK with these final decisions already made:

- Integration is centered on `ReRune.setup(...)`.
- Auth/config is `otaPublishId` only.
- No `projectId`, no `apiKey`, no `rerune.json` runtime file.
- Manifest URL is fixed by SDK and not consumer-configurable.
- Request auth header is `X-OTA-Publish-Id`.
- Fallback is strict: OTA/cache first, then bundled app strings.
- API surface is intentionally small; no consumer-facing controller object.

This iOS spec mirrors that direction.

## Goal

Provide OTA localization updates for iOS with minimal API surface, explicit behavior,
and near-native usage patterns for both UIKit and SwiftUI.

## Lean design principles

- Keep setup to one required credential: `otaPublishId`.
- Keep lookup explicit: no swizzling of system localization APIs.
- Keep fallback native: use `Bundle`/`NSLocalizedString` behavior when OTA misses.
- Keep UI integration opt-in and tiny for UIKit and SwiftUI.
- Keep transport/cache logic internal and replaceable.

## Non-goals (v1)

- No backward-compat shims for old auth/config models.
- No runtime config file (`rerune.json`) on iOS.
- No public override for API host or manifest URL.
- No interception of `Text("key")`, `NSLocalizedString`, storyboard, or nib localization.
- No plurals/stringsdict support in v1 (strings only).

## Naming policy (must match AGENTS.md)

- Consumer-facing types must start with `ReRune`.
- Consumer-facing functions must start with `reRune`.
- Exception: static functions on `ReRune` do not need `reRune` prefix.
- Internal implementation symbols must not start with `ReRune`/`reRune`.

## Platform and packaging

- Distribution: Swift Package Manager.
- Minimum: iOS 15+.
- Modules:
  - `rerune-ios-core` (Foundation + networking + cache + public API)
  - `rerune-ios-swiftui` (small SwiftUI revision bridge helpers)
- UIKit apps use `rerune-ios-core` only.

## Integration UX

### 1) Setup (required)

UIKit (`AppDelegate`):

```swift
import ReRuneCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    ReRune.setup(otaPublishId: "replace-with-ota-publish-id")
    return true
  }
}
```

SwiftUI (`App`):

```swift
import SwiftUI
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

### 2) String usage (closest to native)

UIKit:

```swift
titleLabel.text = reRuneString("home_title")
```

SwiftUI:

```swift
Text(reRuneString("home_title"))
```

### 3) Refresh behavior for already-visible UI

- SwiftUI: `reRuneObserveRevision()` triggers view-tree invalidation on revision changes.
- UIKit: observe `ReRune.revisionPublisher` and rebind visible strings.

```swift
ReRune.revisionPublisher
  .dropFirst()
  .sink { [weak self] _ in self?.rebindStrings() }
  .store(in: &cancellables)
```

## Runtime config and auth

- Required: non-empty `otaPublishId` passed to `ReRune.setup(...)`.
- Missing/blank `otaPublishId` is fail-fast and triggers `preconditionFailure` with an actionable message.
- No other auth inputs are public.

## Networking rules

- Base host is fixed: `https://rerune.io/api`.
- Fixed manifest endpoint:
  - `https://rerune.io/api/sdk/translations/manifest?platform=ios`
- Locale payload URL selection:
  1. Use locale URL from manifest entry when provided.
  2. Else fallback to `https://rerune.io/api/sdk/translations/ios/{locale}`.
- Required request header: `X-OTA-Publish-Id: <otaPublishId>`.
- Use ETag for manifest and locale requests.
- Default timeout: 10 seconds (configurable in setup).

## Data formats

### Manifest

- Parse manifest as JSON.
- Parser should accept practical variants for compatibility (same direction as Android):
  - revision key: `revision` or `version`
  - locale containers: `locales`, `translations`, or `bundles`
  - locale entries as arrays or keyed objects
  - locale entry fields: `locale`/`code`/`language`, `etag`/`version`, `url`/`resource_url`

Example:

```json
{
  "revision": 42,
  "locales": [
    {
      "locale": "en",
      "etag": "W/\"en-42\"",
      "url": "https://rerune.io/api/sdk/translations/ios/en"
    },
    {
      "locale": "de",
      "etag": "W/\"de-42\""
    }
  ]
}
```

### Locale payload

- v1 wire format: UTF-8 JSON object of `stringKey -> localizedValue`.
- Invalid payload is non-fatal: ignore payload, keep cached/bundled fallback.

Example:

```json
{
  "home_title": "Welcome",
  "settings_title": "Settings"
}
```

## Fallback and update behavior

- On setup, load cached manifest/locales first.
- If `checkOnStart == true` (default), run update check once at startup.
- If periodic interval is set, run periodic checks while app process is alive.
- `checkForUpdates()` status semantics:
  - `.updated` when one or more locale bundles changed.
  - `.noChange` when nothing changed.
  - `.failed` when manifest/update step fails.
- If `checkForUpdates()` is called before `ReRune.setup(...)`, return `.failed` with an actionable `errorMessage`.
- String lookup order:
  1. OTA/cache value for locale fallback chain
  2. Bundled iOS localization (`Bundle.main.localizedString(...)`)
  3. Standard iOS key fallback behavior
- Network/parse/cache errors must never crash UI lookup paths.

## Locale resolution

- Build fallback chain from `Locale.preferredLanguages` first value.
- Normalize to BCP-47 style, most specific to least specific.
- Example: `zh-Hant-TW -> zh-Hant -> zh`.

## Public API surface (v1)

```swift
import Foundation
import Combine

public enum ReRune {
  public static func setup(
    otaPublishId: String,
    updatePolicy: ReRuneUpdatePolicy = ReRuneUpdatePolicy(),
    cacheStore: ReRuneCacheStore? = nil,
    requestTimeout: TimeInterval = 10,
    logLevel: ReRuneLogLevel = .warning
  )

  public static func checkForUpdates() async -> ReRuneUpdateResult

  public static var revision: Int { get }

  public static var revisionPublisher: AnyPublisher<Int, Never> { get }
}
```

```swift
public struct ReRuneUpdatePolicy {
  public var checkOnStart: Bool = true
  public var periodicInterval: TimeInterval? = nil
}

public struct ReRuneUpdateResult {
  public let status: ReRuneUpdateStatus
  public let updatedLocales: Set<String>
  public let errorMessage: String?
}

public enum ReRuneUpdateStatus {
  case updated
  case noChange
  case failed
}

public enum ReRuneLogLevel {
  case none
  case error
  case warning
  case info
  case debug
  case verbose
}
```

```swift
public protocol ReRuneCacheStore {
  func reRuneReadManifest() async -> ReRuneCachedManifest?
  func reRuneWriteManifest(_ manifest: ReRuneCachedManifest) async
  func reRuneReadLocaleBundle(localeTag: String) async -> ReRuneCachedLocaleBundle?
  func reRuneWriteLocaleBundle(_ bundle: ReRuneCachedLocaleBundle) async
  func reRuneReadAllLocaleBundles() async -> [ReRuneCachedLocaleBundle]
}

public struct ReRuneCachedManifest {
  public let body: String
  public let etag: String?
}

public struct ReRuneCachedLocaleBundle {
  public let localeTag: String
  public let payloadJson: String
  public let etag: String?
}
```

```swift
public func reRuneString(
  _ key: String,
  tableName: String? = nil,
  bundle: Bundle = .main,
  value: String? = nil,
  comment: String = ""
) -> String
```

SwiftUI helper module:

```swift
import SwiftUI

public extension View {
  func reRuneObserveRevision() -> some View
}
```

## Internal architecture (recommended)

- `LocalizationController` actor: state, revision, lookup, update orchestration.
- `ManifestClient`: fetch and validate manifest + ETag handling.
- `TranslationClient`: fetch locale payloads + ETag handling.
- `DiskCacheStore`: default file-based cache.
- `SdkLogger`: internal logging utility.

## Storage and performance

- Default cache path: `Application Support/ReRune/`.
- Keep in-memory map of currently loaded locale bundles for O(1) key lookup.
- Avoid blocking main thread for network, parse, or disk I/O.
- Lookup path should be synchronous and fast after warm cache.

## Error policy

- Setup config errors are explicit and actionable.
- Update errors are non-fatal and returned as `failed` while preserving current cache.
- All failures emit logs based on `ReRuneLogLevel`.

## Testing requirements

- Unit tests:
  - `otaPublishId` validation.
  - Header/endpoint correctness (`X-OTA-Publish-Id`, fixed manifest URL).
  - ETag behavior for manifest and locale payloads.
  - `checkForUpdates()` before setup returns `failed` with error message.
  - Locale fallback chain lookup.
  - Cache-first startup and network fallback.
  - Timeout handling.
  - Revision propagation and observer emissions.
- SwiftUI module tests:
  - `reRuneObserveRevision()` causes refresh when revision changes.

## Acceptance criteria

1. Minimal integration works with only `ReRune.setup(...)` and `reRuneString(...)`.
2. No `projectId`, `apiKey`, `rerune.json`, or manifest URL public override exists.
3. Offline mode still returns bundled strings.
4. UIKit and SwiftUI can refresh visible text on revision changes.
5. SDK remains opt-in and does not alter system localization APIs globally.
6. Public API follows AGENTS naming rules.

## Prompt template for implementation

Use this in a future coding session:

```text
Implement the iOS SDK described in iOS_SPECS.md.

Constraints:
- Keep API minimal and centered on ReRune.setup(...).
- Use otaPublishId-only auth with X-OTA-Publish-Id header.
- Keep manifest URL fixed to platform=ios.
- Do not use swizzling or global interception of NSLocalizedString/Text.
- Make lookup explicit via reRuneString(...), with strict fallback to bundled strings.
- Keep network/parse failures non-fatal.

Deliverables:
1) Swift package modules: rerune-ios-core and rerune-ios-swiftui.
2) Public API exactly as spec or with clearly documented deviations.
3) Unit tests for config, fallback, ETag, timeout, revision updates.
4) README examples for UIKit and SwiftUI integration.
5) Changelog entry for iOS SDK addition and breaking/lean API decisions.
```
