public struct ReRuneUpdateResult: Sendable {
    public let status: ReRuneUpdateStatus
    public let updatedLocales: Set<String>
    public let errorMessage: String?

    public init(
        status: ReRuneUpdateStatus,
        updatedLocales: Set<String> = [],
        errorMessage: String? = nil
    ) {
        self.status = status
        self.updatedLocales = updatedLocales
        self.errorMessage = errorMessage
    }
}
