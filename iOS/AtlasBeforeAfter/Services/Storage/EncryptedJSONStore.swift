import Foundation

final class EncryptedJSONStore<T: Codable> {
    private let fileStore: EncryptedFileStore
    private let filePath: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(fileStore: EncryptedFileStore = EncryptedFileStore(), filePath: String) {
        self.fileStore = fileStore
        self.filePath = filePath
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func load(defaultValue: T) -> T {
        guard fileStore.exists(filePath) else { return defaultValue }
        do {
            let data = try fileStore.read(from: filePath)
            return try decoder.decode(T.self, from: data)
        } catch {
            return defaultValue
        }
    }

    func save(_ value: T) throws {
        let data = try encoder.encode(value)
        _ = try fileStore.write(data: data, to: filePath)
    }
}
