import Foundation

enum manifestParser {
    static func parse(jsonString: String) throws -> manifestModel {
        let data = Data(jsonString.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any] else {
            throw parsingError.invalidManifest
        }

        let revision = intValue(root["revision"]) ?? intValue(root["version"]) ?? 0
        let localeEntries = parseLocales(from: root)
        return manifestModel(revision: revision, locales: localeEntries)
    }

    private static func parseLocales(from root: [String: Any]) -> [manifestModel.localeEntry] {
        let container = root["locales"] ?? root["translations"] ?? root["bundles"]
        if let array = container as? [[String: Any]] {
            return array.compactMap { parseLocale(entry: $0, fallbackTag: nil) }
        }

        if let keyed = container as? [String: Any] {
            return keyed.compactMap { key, value in
                if let dict = value as? [String: Any] {
                    return parseLocale(entry: dict, fallbackTag: key)
                }
                return manifestModel.localeEntry(locale: key, etag: nil, url: nil)
            }
        }

        return []
    }

    private static func parseLocale(entry: [String: Any], fallbackTag: String?) -> manifestModel.localeEntry? {
        let locale = stringValue(entry["locale"]) ?? stringValue(entry["code"]) ?? stringValue(entry["language"]) ?? fallbackTag
        guard let locale, !locale.isEmpty else { return nil }

        let etag = stringValue(entry["etag"]) ?? stringValue(entry["version"])
        let urlString = stringValue(entry["url"]) ?? stringValue(entry["resource_url"])
        let url = urlString.flatMap(URL.init(string:))
        return manifestModel.localeEntry(locale: locale, etag: etag, url: url)
    }

    private static func intValue(_ value: Any?) -> Int? {
        switch value {
        case let int as Int:
            return int
        case let string as String:
            return Int(string)
        case let number as NSNumber:
            return number.intValue
        default:
            return nil
        }
    }

    private static func stringValue(_ value: Any?) -> String? {
        switch value {
        case let string as String:
            return string
        case let number as NSNumber:
            return number.stringValue
        default:
            return nil
        }
    }
}

enum parsingError: Error {
    case invalidManifest
    case invalidLocalePayload
}
