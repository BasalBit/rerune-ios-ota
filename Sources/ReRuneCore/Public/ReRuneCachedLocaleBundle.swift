public struct ReRuneCachedLocaleBundle: Codable, Sendable {
    public let localeTag: String
    public let payloadJson: String
    public let etag: String?

    public init(localeTag: String, payloadJson: String, etag: String?) {
        self.localeTag = localeTag
        self.payloadJson = payloadJson
        self.etag = etag
    }
}
