import Foundation

enum requestBuilder {
    static let host = "https://rerune.io/api"
    static let manifestURL = URL(string: "https://rerune.io/api/sdk/translations/manifest?platform=ios")!

    static func manifestRequest(otaPublishId: String, etag: String?) -> URLRequest {
        var request = URLRequest(url: manifestURL)
        request.httpMethod = "GET"
        request.setValue(otaPublishId, forHTTPHeaderField: "X-OTA-Publish-Id")
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        return request
    }

    static func localeRequest(localeTag: String, url: URL?, otaPublishId: String, etag: String?) -> URLRequest? {
        let resolvedURL = url ?? URL(string: "\(host)/sdk/translations/ios/\(localeTag)")
        guard let resolvedURL else { return nil }

        var request = URLRequest(url: resolvedURL)
        request.httpMethod = "GET"
        request.setValue(otaPublishId, forHTTPHeaderField: "X-OTA-Publish-Id")
        if let etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        return request
    }
}
