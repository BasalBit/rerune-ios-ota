public protocol ReRuneCacheStore: Sendable {
    func reRuneReadManifest() async -> ReRuneCachedManifest?
    func reRuneWriteManifest(_ manifest: ReRuneCachedManifest) async
    func reRuneReadLocaleBundle(localeTag: String) async -> ReRuneCachedLocaleBundle?
    func reRuneWriteLocaleBundle(_ bundle: ReRuneCachedLocaleBundle) async
    func reRuneReadAllLocaleBundles() async -> [ReRuneCachedLocaleBundle]
}
