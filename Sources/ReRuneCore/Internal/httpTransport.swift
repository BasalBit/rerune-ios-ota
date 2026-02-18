import Foundation

protocol httpTransport: Sendable {
    func send(_ request: URLRequest, timeout: TimeInterval) async throws -> (Data, HTTPURLResponse)
}

struct urlSessionTransport: httpTransport {
    func send(_ request: URLRequest, timeout: TimeInterval) async throws -> (Data, HTTPURLResponse) {
        var request = request
        request.timeoutInterval = timeout
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw transportError.invalidResponse
        }
        return (data, httpResponse)
    }
}

enum transportError: Error {
    case invalidResponse
}
