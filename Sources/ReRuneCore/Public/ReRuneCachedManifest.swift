public struct ReRuneCachedManifest: Codable, Sendable {
    public let body: String
    public let etag: String?

    public init(body: String, etag: String?) {
        self.body = body
        self.etag = etag
    }
}
