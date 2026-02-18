import Combine
import Foundation

public enum ReRune {
    public static func setup(
        otaPublishId: String,
        updatePolicy: ReRuneUpdatePolicy = ReRuneUpdatePolicy(),
        cacheStore: ReRuneCacheStore? = nil,
        requestTimeout: TimeInterval = 10,
        logLevel: ReRuneLogLevel = .warning
    ) {
        let trimmed = otaPublishId.trimmingCharacters(in: .whitespacesAndNewlines)
        precondition(!trimmed.isEmpty, "ReRune.setup requires a non-empty otaPublishId.")

        let runtime = runtimeState.shared
        runtime.startupTask?.cancel()
        runtime.periodicTask?.cancel()

        let store = cacheStore ?? diskCacheStore()
        let transport = transportOverrideForTests ?? urlSessionTransport()
        let controller = localizationController(
            otaPublishId: trimmed,
            updatePolicy: updatePolicy,
            cacheStore: store,
            requestTimeout: requestTimeout,
            logLevel: logLevel,
            transport: transport,
            lookup: runtime.lookup,
            onRevision: { revision in runtime.setRevision(revision) }
        )

        runtime.controller = controller
        runtime.startupTask = Task {
            await controller.bootstrapFromCache()
        }

        if let interval = updatePolicy.periodicInterval, interval > 0 {
            runtime.periodicTask = Task {
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
                    guard !Task.isCancelled else { break }
                    _ = await controller.checkForUpdates()
                }
            }
        }
    }

    public static func checkForUpdates() async -> ReRuneUpdateResult {
        guard let controller = runtimeState.shared.controller else {
            return ReRuneUpdateResult(
                status: .failed,
                errorMessage: "ReRune.setup(...) must be called before checkForUpdates()."
            )
        }
        return await controller.checkForUpdates()
    }

    public static var revision: Int {
        runtimeState.shared.revision()
    }

    public static var revisionPublisher: AnyPublisher<Int, Never> {
        runtimeState.shared.revisionPublisher()
    }
}
