import Foundation

struct manifestClient: Sendable {
    enum outcome: Sendable {
        case noChange
        case manifest(body: String, etag: String?)
    }

    let transport: httpTransport
    let timeout: TimeInterval

    func fetch(otaPublishId: String, etag: String?) async throws -> outcome {
        let request = requestBuilder.manifestRequest(otaPublishId: otaPublishId, etag: etag)
        let (data, response) = try await transport.send(request, timeout: timeout)
        switch response.statusCode {
        case 304:
            return .noChange
        case 200:
            let body = String(data: data, encoding: .utf8) ?? "{}"
            return .manifest(body: body, etag: response.value(forHTTPHeaderField: "ETag"))
        default:
            throw updateError.badStatus(code: response.statusCode)
        }
    }
}

enum updateError: Error {
    case badStatus(code: Int)
}
