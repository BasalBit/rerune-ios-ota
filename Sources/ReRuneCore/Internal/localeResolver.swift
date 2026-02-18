import Foundation

enum localeResolver {
    static func preferredChain() -> [String] {
        guard let first = Locale.preferredLanguages.first, !first.isEmpty else {
            return ["en"]
        }
        return buildChain(from: first)
    }

    static func buildChain(from localeTag: String) -> [String] {
        let normalized = localeTag.replacingOccurrences(of: "_", with: "-")
        let parts = normalized.split(separator: "-").map(String.init)
        guard !parts.isEmpty else { return ["en"] }

        var chain: [String] = []
        for index in stride(from: parts.count, through: 1, by: -1) {
            chain.append(parts.prefix(index).joined(separator: "-"))
        }
        return chain
    }
}
