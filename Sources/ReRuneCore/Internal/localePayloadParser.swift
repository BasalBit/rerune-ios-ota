import Foundation

enum localePayloadParser {
    static func parse(jsonString: String) throws -> [String: String] {
        let data = Data(jsonString.utf8)
        let object = try JSONSerialization.jsonObject(with: data)
        guard let root = object as? [String: Any] else {
            throw parsingError.invalidLocalePayload
        }

        var values: [String: String] = [:]
        for (key, value) in root {
            if let string = value as? String {
                values[key] = string
            } else if let number = value as? NSNumber {
                values[key] = number.stringValue
            }
        }
        return values
    }
}
