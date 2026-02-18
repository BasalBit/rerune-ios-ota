import Foundation

struct sdkLogger: Sendable {
    let level: ReRuneLogLevel

    func error(_ message: String) {
        write(message, requiredLevel: .error)
    }

    func warning(_ message: String) {
        write(message, requiredLevel: .warning)
    }

    func info(_ message: String) {
        write(message, requiredLevel: .info)
    }

    func debug(_ message: String) {
        write(message, requiredLevel: .debug)
    }

    private func write(_ message: String, requiredLevel: ReRuneLogLevel) {
        guard level.rawValue >= requiredLevel.rawValue, level != .none else { return }
        print("[ReRune] \(message)")
    }
}
