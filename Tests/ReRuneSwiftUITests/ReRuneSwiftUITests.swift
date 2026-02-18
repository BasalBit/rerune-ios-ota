import Combine
import Foundation
import XCTest
@testable import ReRuneCore
@testable import ReRuneSwiftUI

final class ReRuneSwiftUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        sdkResetForTests()
    }

    override func tearDown() {
        sdkResetForTests()
        super.tearDown()
    }

    func testRevisionObserverReceivesUpdates() async {
        let transport = swiftUIMockTransport()
        let manifest = """
        {
          "revision": 11,
          "locales": [
            {"locale": "en"}
          ]
        }
        """
        await transport.enqueue(path: "/sdk/translations/manifest", statusCode: 200, body: manifest)
        await transport.enqueue(path: "/sdk/translations/ios/en", statusCode: 200, body: "{\"home_title\":\"Welcome\"}")
        sdkConfigureTransportForTests(transport)

        let observer = revisionObserver()
        let expectation = expectation(description: "observer receives revision")
        var cancellables = Set<AnyCancellable>()

        observer.$revision
            .dropFirst()
            .sink { value in
                if value == 11 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        ReRune.setup(
            otaPublishId: "publish-id",
            updatePolicy: ReRuneUpdatePolicy(checkOnStart: false)
        )
        _ = await ReRune.checkForUpdates()

        await fulfillment(of: [expectation], timeout: 1.5)
    }
}

private actor swiftUIMockTransport: httpTransport {
    struct queuedResponse {
        let path: String
        let statusCode: Int
        let body: String
    }

    private var queue: [queuedResponse] = []

    func enqueue(path: String, statusCode: Int, body: String) {
        queue.append(queuedResponse(path: path, statusCode: statusCode, body: body))
    }

    func send(_ request: URLRequest, timeout: TimeInterval) async throws -> (Data, HTTPURLResponse) {
        _ = timeout
        guard !queue.isEmpty else {
            throw updateError.badStatus(code: 599)
        }
        let response = queue.removeFirst()
        guard request.url?.path.hasSuffix(response.path) == true else {
            throw updateError.badStatus(code: 598)
        }

        let http = HTTPURLResponse(
            url: request.url!,
            statusCode: response.statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (Data(response.body.utf8), http)
    }
}
