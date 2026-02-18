import Foundation

actor localizationController {
    private let otaPublishId: String
    private let updatePolicy: ReRuneUpdatePolicy
    private let cacheStore: ReRuneCacheStore
    private let manifestService: manifestClient
    private let translationService: translationClient
    private let logger: sdkLogger
    private let lookup: lookupSnapshot
    private let onRevision: @Sendable (Int) -> Void

    private var cachedManifestEtag: String?
    private var localeEtags: [String: String] = [:]
    private var localeBundles: [String: [String: String]] = [:]
    private var revision: Int = 0

    init(
        otaPublishId: String,
        updatePolicy: ReRuneUpdatePolicy,
        cacheStore: ReRuneCacheStore,
        requestTimeout: TimeInterval,
        logLevel: ReRuneLogLevel,
        transport: httpTransport,
        lookup: lookupSnapshot,
        onRevision: @escaping @Sendable (Int) -> Void
    ) {
        self.otaPublishId = otaPublishId
        self.updatePolicy = updatePolicy
        self.cacheStore = cacheStore
        self.manifestService = manifestClient(transport: transport, timeout: requestTimeout)
        self.translationService = translationClient(transport: transport, timeout: requestTimeout)
        self.logger = sdkLogger(level: logLevel)
        self.lookup = lookup
        self.onRevision = onRevision
    }

    func bootstrapFromCache() async {
        if let cachedManifest = await cacheStore.reRuneReadManifest() {
            cachedManifestEtag = cachedManifest.etag
            if let parsed = try? manifestParser.parse(jsonString: cachedManifest.body) {
                revision = parsed.revision
            }
        }

        let cachedLocales = await cacheStore.reRuneReadAllLocaleBundles()
        for locale in cachedLocales {
            localeEtags[locale.localeTag] = locale.etag
            if let values = try? localePayloadParser.parse(jsonString: locale.payloadJson) {
                localeBundles[locale.localeTag] = values
            }
        }

        lookup.replaceAll(with: localeBundles)
        onRevision(revision)

        if updatePolicy.checkOnStart {
            _ = await checkForUpdates()
        }
    }

    func checkForUpdates() async -> ReRuneUpdateResult {
        do {
            let manifestResult = try await manifestService.fetch(otaPublishId: otaPublishId, etag: cachedManifestEtag)
            switch manifestResult {
            case .noChange:
                return ReRuneUpdateResult(status: .noChange)
            case let .manifest(body, etag):
                return await applyManifest(body: body, etag: etag)
            }
        } catch {
            logger.warning("Manifest update failed: \(error)")
            return ReRuneUpdateResult(status: .failed, errorMessage: "Failed to fetch OTA manifest.")
        }
    }

    func periodicInterval() -> TimeInterval? {
        updatePolicy.periodicInterval
    }

    private func applyManifest(body: String, etag: String?) async -> ReRuneUpdateResult {
        do {
            let manifest = try manifestParser.parse(jsonString: body)

            var updatedLocales: Set<String> = []
            var hadFailure = false
            for locale in manifest.locales {
                let currentEtag = localeEtags[locale.locale]
                do {
                    let outcome = try await translationService.fetch(
                        localeTag: locale.locale,
                        url: locale.url,
                        otaPublishId: otaPublishId,
                        etag: currentEtag
                    )
                    switch outcome {
                    case .noChange:
                        continue
                    case let .payload(json, responseEtag):
                        let values = try localePayloadParser.parse(jsonString: json)
                        localeBundles[locale.locale] = values
                        localeEtags[locale.locale] = responseEtag ?? locale.etag
                        lookup.set(locale: locale.locale, values: values)

                        let cached = ReRuneCachedLocaleBundle(
                            localeTag: locale.locale,
                            payloadJson: json,
                            etag: responseEtag ?? locale.etag
                        )
                        await cacheStore.reRuneWriteLocaleBundle(cached)
                        updatedLocales.insert(locale.locale)
                    }
                } catch parsingError.invalidLocalePayload {
                    logger.warning("Invalid locale payload for \(locale.locale).")
                    hadFailure = true
                } catch {
                    logger.warning("Locale update failed for \(locale.locale): \(error)")
                    hadFailure = true
                }
            }

            let cachedManifest = ReRuneCachedManifest(body: body, etag: etag)
            await cacheStore.reRuneWriteManifest(cachedManifest)
            cachedManifestEtag = etag

            if !updatedLocales.isEmpty {
                revision = manifest.revision
                onRevision(revision)
                return ReRuneUpdateResult(status: .updated, updatedLocales: updatedLocales)
            }

            if hadFailure {
                return ReRuneUpdateResult(status: .failed, errorMessage: "One or more locales failed to update.")
            }

            return ReRuneUpdateResult(status: .noChange)
        } catch {
            logger.warning("Manifest parsing failed: \(error)")
            return ReRuneUpdateResult(status: .failed, errorMessage: "Failed to parse OTA manifest.")
        }
    }
}
