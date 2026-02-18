import Foundation

public struct ReRuneUpdatePolicy: Sendable {
    public var checkOnStart: Bool
    public var periodicInterval: TimeInterval?

    public init(checkOnStart: Bool = true, periodicInterval: TimeInterval? = nil) {
        self.checkOnStart = checkOnStart
        self.periodicInterval = periodicInterval
    }
}
