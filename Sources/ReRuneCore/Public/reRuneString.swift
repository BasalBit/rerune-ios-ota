import Foundation

public func reRuneString(
    _ key: String,
    tableName: String? = nil,
    bundle: Bundle = .main,
    value: String? = nil,
    comment: String = ""
) -> String {
    _ = comment
    let chain = localeResolver.preferredChain()
    if let otaValue = runtimeState.shared.lookup.value(key: key, localeChain: chain) {
        return otaValue
    }

    return bundle.localizedString(forKey: key, value: value, table: tableName)
}
