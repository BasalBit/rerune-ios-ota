import Combine
import Foundation
import XCTest
@testable import ReRuneCore

final class ReRuneCoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        sdkResetForTests()
    }

    override func tearDown() {
        sdkResetForTests()
        super.tearDown()
    }

    func testCheckBeforeSetupReturnsFailed() async {
        let result = await ReRune.checkForUpdates()
        XCTAssertEqual(result.status, .failed)
        XCTAssertNotNil(result.errorMessage)
    }

    func testManifestRequestContainsFixedURLAndHeader() async {
        let transport = mockTransport()
        await transport.enqueue(path: "/sdk/translations/manifest", statusCode: 304, body: "")
        sdkConfigureTransportForTests(transport)

        ReRune.setup(
            otaPublishId: "publish-id",
            updatePolicy: ReRuneUpdatePolicy(checkOnStart: false)
        )

        _ = await ReRune.checkForUpdates()
        let requests = await transport.capturedRequests()
        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].url?.absoluteString, "https://rerune.io/api/sdk/translations/manifest?platform=ios")
        XCTAssertEqual(requests[0].value(forHTTPHeaderField: "X-OTA-Publish-Id"), "publish-id")
    }

    func testETagBehaviorForManifestAndLocaleRequests() async {
        let transport = mockTransport()
        let manifest = """
        {
          "revision": 2,
          "locales": [
            {"locale": "en", "etag": "W/\\\"en-2\\\""}
          ]
        }
        """
        await transport.enqueue(path: "/sdk/translations/manifest", statusCode: 200, body: manifest, etag: "W/\"manifest-2\"")
        await transport.enqueue(path: "/sdk/translations/ios/en", statusCode: 304, body: "")
        sdkConfigureTransportForTests(transport)

        let cache = inMemoryCacheStore(
            manifest: ReRuneCachedManifest(body: manifest, etag: "W/\"manifest-1\""),
            locales: [ReRuneCachedLocaleBundle(localeTag: "en", payloadJson: "{\"home_title\":\"Hello\"}", etag: "W/\"en-1\"")]
        )

        ReRune.setup(
            otaPublishId: "publish-id",
            updatePolicy: ReRuneUpdatePolicy(checkOnStart: false),
            cacheStore: cache
        )

        try? await Task.sleep(nanoseconds: 80_000_000)
        _ = await ReRune.checkForUpdates()
        let requests = await transport.capturedRequests()
        XCTAssertGreaterThanOrEqual(requests.count, 2)
        XCTAssertEqual(requests[0].value(forHTTPHeaderField: "If-None-Match"), "W/\"manifest-1\"")
        XCTAssertEqual(requests[1].value(forHTTPHeaderField: "If-None-Match"), "W/\"en-1\"")
    }

    func testCacheFirstLookupFallback() async {
        let cache = inMemoryCacheStore(
            manifest: nil,
            locales: [ReRuneCachedLocaleBundle(localeTag: "en", payloadJson: "{\"home_title\":\"Welcome OTA\"}", etag: nil)]
        )

        ReRune.setup(
            otaPublishId: "publish-id",
            updatePolicy: ReRuneUpdatePolicy(checkOnStart: false),
            cacheStore: cache
        )

        try? await Task.sleep(nanoseconds: 100_000_000)
        let value = reRuneString("home_title", bundle: .main)
        XCTAssertEqual(value, "Welcome OTA")
    }

    func testFailedLocaleUpdateReturnsFailedStatus() async {
        let transport = mockTransport()
        let manifest = """
        {
          "revision": 3,
          "locales": [
            {"locale": "en"}
          ]
        }
        """
        await transport.enqueue(path: "/sdk/translations/manifest", statusCode: 200, body: manifest)
        await transport.enqueue(path: "/sdk/translations/ios/en", statusCode: 500, body: "")
        sdkConfigureTransportForTests(transport)

        ReRune.setup(
            otaPublishId: "publish-id",
            updatePolicy: ReRuneUpdatePolicy(checkOnStart: false)
        )

        let result = await ReRune.checkForUpdates()
        XCTAssertEqual(result.status, .failed)
    }

    func testRevisionPublisherEmitsOnUpdate() async {
        let transport = mockTransport()
        let manifest = """
        {
          "revision": 7,
          "locales": [
            {"locale": "en"}
          ]
        }
        """
        await transport.enqueue(path: "/sdk/translations/manifest", statusCode: 200, body: manifest)
        await transport.enqueue(path: "/sdk/translations/ios/en", statusCode: 200, body: "{\"home_title\":\"Welcome\"}")
        sdkConfigureTransportForTests(transport)

        var cancellables = Set<AnyCancellable>()
        let expectation = expectation(description: "revision emitted")
        ReRune.revisionPublisher
            .dropFirst()
            .sink { value in
                if value == 7 {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        ReRune.setup(
            otaPublishId: "publish-id",
            updatePolicy: ReRuneUpdatePolicy(checkOnStart: false)
        )

        let result = await ReRune.checkForUpdates()
        XCTAssertEqual(result.status, .updated)
        await fulfillment(of: [expectation], timeout: 1.5)
        XCTAssertEqual(ReRune.revision, 7)
    }
}

private actor inMemoryCacheStore: ReRuneCacheStore {
    private var manifest: ReRuneCachedManifest?
    private var locales: [String: ReRuneCachedLocaleBundle]

    init(manifest: ReRuneCachedManifest?, locales: [ReRuneCachedLocaleBundle]) {
        self.manifest = manifest
        self.locales = Dictionary(uniqueKeysWithValues: locales.map { ($0.localeTag, $0) })
    }

    func reRuneReadManifest() async -> ReRuneCachedManifest? { manifest }
    func reRuneWriteManifest(_ manifest: ReRuneCachedManifest) async { self.manifest = manifest }
    func reRuneReadLocaleBundle(localeTag: String) async -> ReRuneCachedLocaleBundle? { locales[localeTag] }
    func reRuneWriteLocaleBundle(_ bundle: ReRuneCachedLocaleBundle) async { locales[bundle.localeTag] = bundle }
    func reRuneReadAllLocaleBundles() async -> [ReRuneCachedLocaleBundle] { Array(locales.values) }
}

private actor mockTransport: httpTransport {
    struct queuedResponse {
        let path: String
        let statusCode: Int
        let body: String
        let etag: String?
    }

    private var queue: [queuedResponse] = []
    private var requests: [URLRequest] = []

    func enqueue(path: String, statusCode: Int, body: String, etag: String? = nil) {
        queue.append(queuedResponse(path: path, statusCode: statusCode, body: body, etag: etag))
    }

    func capturedRequests() -> [URLRequest] {
        requests
    }

    func send(_ request: URLRequest, timeout: TimeInterval) async throws -> (Data, HTTPURLResponse) {
        _ = timeout
        requests.append(request)
        guard !queue.isEmpty else {
            throw updateError.badStatus(code: 599)
        }

        let first = queue.removeFirst()
        guard request.url?.path.hasSuffix(first.path) == true else {
            throw updateError.badStatus(code: 598)
        }

        var headers: [String: String] = [:]
        if let etag = first.etag {
            headers["ETag"] = etag
        }
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: first.statusCode,
            httpVersion: nil,
            headerFields: headers
        )!
        return (Data(first.body.utf8), response)
    }
}
