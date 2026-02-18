import Foundation

struct translationClient: Sendable {
    enum outcome: Sendable {
        case noChange
        case payload(json: String, etag: String?)
    }

    let transport: httpTransport
    let timeout: TimeInterval

    func fetch(localeTag: String, url: URL?, otaPublishId: String, etag: String?) async throws -> outcome {
        guard let request = requestBuilder.localeRequest(localeTag: localeTag, url: url, otaPublishId: otaPublishId, etag: etag) else {
            throw updateError.badStatus(code: 0)
        }

        let (data, response) = try await transport.send(request, timeout: timeout)
        switch response.statusCode {
        case 304:
            return .noChange
        case 200:
            let body = String(data: data, encoding: .utf8) ?? "{}"
            return .payload(json: body, etag: response.value(forHTTPHeaderField: "ETag"))
        default:
            throw updateError.badStatus(code: response.statusCode)
        }
    }
}
