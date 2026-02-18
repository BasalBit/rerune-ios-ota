import Foundation

struct manifestModel: Sendable {
    struct localeEntry: Sendable {
        let locale: String
        let etag: String?
        let url: URL?
    }

    let revision: Int
    let locales: [localeEntry]
}
