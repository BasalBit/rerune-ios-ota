import Combine
import Foundation

final class runtimeState {
    static let shared = runtimeState()

    private let lock = NSLock()
    private let revisionSubject = CurrentValueSubject<Int, Never>(0)

    var controller: localizationController?
    var periodicTask: Task<Void, Never>?
    var startupTask: Task<Void, Never>?
    let lookup = lookupSnapshot()

    private var revisionValue = 0
    private init() {}

    func setRevision(_ revision: Int) {
        lock.lock()
        revisionValue = revision
        lock.unlock()
        revisionSubject.send(revision)
    }

    func revision() -> Int {
        lock.lock()
        defer { lock.unlock() }
        return revisionValue
    }

    func revisionPublisher() -> AnyPublisher<Int, Never> {
        revisionSubject.eraseToAnyPublisher()
    }

    func resetRuntime() {
        startupTask?.cancel()
        periodicTask?.cancel()
        startupTask = nil
        periodicTask = nil
        controller = nil
        lookup.replaceAll(with: [:])
        setRevision(0)
    }
}

final class lookupSnapshot {
    private let lock = NSLock()
    private var storage: [String: [String: String]] = [:]

    func replaceAll(with bundles: [String: [String: String]]) {
        lock.lock()
        storage = bundles
        lock.unlock()
    }

    func set(locale: String, values: [String: String]) {
        lock.lock()
        storage[locale] = values
        lock.unlock()
    }

    func value(key: String, localeChain: [String]) -> String? {
        lock.lock()
        defer { lock.unlock() }
        for locale in localeChain {
            if let value = storage[locale]?[key] {
                return value
            }
        }
        return nil
    }
}
