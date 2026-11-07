import Foundation
import Security

/// `APIKeyStore` backed by the Keychain. Nothing else in this app stores secrets,
/// and the key never touches `UserDefaults` or disk in plain text.
public struct KeychainStore: APIKeyStore {
    private let service: String

    public init(service: String = "com.notenroll.claude-api-key") {
        self.service = service
    }

    public func save(apiKey: String) throws {
        let data = Data(apiKey.utf8)
        var query = baseQuery()
        query[kSecValueData as String] = data

        let deleteStatus = SecItemDelete(baseQuery() as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            throw KeychainError.unhandled(status: deleteStatus)
        }

        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw KeychainError.unhandled(status: addStatus)
        }
    }

    public func loadAPIKey() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let key = String(data: data, encoding: .utf8) else {
                throw KeychainError.corruptValue
            }
            return key
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unhandled(status: status)
        }
    }

    public func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandled(status: status)
        }
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
    }
}

public enum KeychainError: Error, Sendable, Equatable {
    case unhandled(status: OSStatus)
    case corruptValue
}
