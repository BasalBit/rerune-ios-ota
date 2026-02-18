import Foundation

actor diskCacheStore: ReRuneCacheStore {
    private let fileManager = FileManager.default
    private let rootURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        let localesDirectory: URL
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            rootURL = appSupport.appendingPathComponent("ReRune", isDirectory: true)
        } else {
            rootURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("ReRune", isDirectory: true)
        }
        localesDirectory = rootURL.appendingPathComponent("locales", isDirectory: true)
        try? fileManager.createDirectory(at: rootURL, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: localesDirectory, withIntermediateDirectories: true)
    }

    func reRuneReadManifest() async -> ReRuneCachedManifest? {
        read(file: manifestURL, as: ReRuneCachedManifest.self)
    }

    func reRuneWriteManifest(_ manifest: ReRuneCachedManifest) async {
        write(manifest, to: manifestURL)
    }

    func reRuneReadLocaleBundle(localeTag: String) async -> ReRuneCachedLocaleBundle? {
        read(file: localeURL(localeTag: localeTag), as: ReRuneCachedLocaleBundle.self)
    }

    func reRuneWriteLocaleBundle(_ bundle: ReRuneCachedLocaleBundle) async {
        write(bundle, to: localeURL(localeTag: bundle.localeTag))
    }

    func reRuneReadAllLocaleBundles() async -> [ReRuneCachedLocaleBundle] {
        guard let urls = try? fileManager.contentsOfDirectory(
            at: localesDirectoryURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return urls.compactMap { read(file: $0, as: ReRuneCachedLocaleBundle.self) }
    }

    private var manifestURL: URL {
        rootURL.appendingPathComponent("manifest.json")
    }

    private var localesDirectoryURL: URL {
        rootURL.appendingPathComponent("locales", isDirectory: true)
    }

    private func localeURL(localeTag: String) -> URL {
        let sanitized = localeTag.replacingOccurrences(of: "/", with: "-")
        return localesDirectoryURL.appendingPathComponent("\(sanitized).json")
    }

    private func read<T: Decodable>(file: URL, as type: T.Type) -> T? {
        guard let data = try? Data(contentsOf: file) else { return nil }
        return try? decoder.decode(T.self, from: data)
    }

    private func write<T: Encodable>(_ value: T, to url: URL) {
        guard let data = try? encoder.encode(value) else { return }
        try? data.write(to: url, options: [.atomic])
    }
}
