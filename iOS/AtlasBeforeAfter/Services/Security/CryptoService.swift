import Foundation
import CryptoKit

final class CryptoService {
    private let keychain: KeychainService
    private let keyAccount = "encryption-key-v1"

    init(keychain: KeychainService = KeychainService()) {
        self.keychain = keychain
    }

    private func loadOrCreateKey() throws -> SymmetricKey {
        if let data = try keychain.get(keyAccount) {
            return SymmetricKey(data: data)
        }
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        try keychain.set(data, for: keyAccount)
        return key
    }

    func encrypt(_ plaintext: Data, associatedData: Data? = nil) throws -> Data {
        let key = try loadOrCreateKey()
        let sealed = try AES.GCM.seal(plaintext, using: key, authenticating: associatedData ?? Data())
        guard let combined = sealed.combined else { throw CryptoError.combinationFailed }
        return combined
    }

    func decrypt(_ ciphertext: Data, associatedData: Data? = nil) throws -> Data {
        let key = try loadOrCreateKey()
        let sealed = try AES.GCM.SealedBox(combined: ciphertext)
        return try AES.GCM.open(sealed, using: key, authenticating: associatedData ?? Data())
    }

    enum CryptoError: Error { case combinationFailed }
}
