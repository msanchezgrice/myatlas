import Foundation

final class EncryptedFileStore {
    private let crypto: CryptoService
    private let fileManager = FileManager.default

    init(crypto: CryptoService = CryptoService()) {
        self.crypto = crypto
        try? ensureAppSupport()
    }

    private func appSupportURL() throws -> URL {
        let urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        guard let base = urls.first else { throw StoreError.directory }
        let dir = base.appendingPathComponent("AtlasBeforeAfter", isDirectory: true)
        return dir
    }

    private func ensureAppSupport() throws {
        let dir = try appSupportURL()
        if !fileManager.fileExists(atPath: dir.path) {
            try fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        var mutableDir = dir
        try mutableDir.setResourceValues(resourceValues)
    }

    func write(data: Data, to relativePath: String) throws -> URL {
        let url = try appSupportURL().appendingPathComponent(relativePath)
        let enc = try crypto.encrypt(data)
        try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try enc.write(to: url, options: [.atomic])
        return url
    }

    func read(from relativePath: String) throws -> Data {
        let url = try appSupportURL().appendingPathComponent(relativePath)
        let enc = try Data(contentsOf: url)
        return try crypto.decrypt(enc)
    }

    func exists(_ relativePath: String) -> Bool {
        guard let url = try? appSupportURL().appendingPathComponent(relativePath) else { return false }
        return fileManager.fileExists(atPath: url.path)
    }

    enum StoreError: Error { case directory }
}
