import Foundation
import Security

public final class KeychainManager: Sendable {
    public static let shared = KeychainManager()
    private let serviceName = "com.antigravity.echo.credentials"
    
    public init() {}
    
    public func save(key: String, account: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        delete(account: account)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecSuccess {
            EchoLogger.ai.info("Saved API key securely to macOS Keychain for \(account, privacy: .public)")
            return true
        } else {
            EchoLogger.ai.error("Failed to save API key to Keychain: \(status)")
            return false
        }
    }
    
    public func read(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
    public func delete(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        EchoLogger.ai.info("Removed key from Keychain for \(account, privacy: .public)")
    }
}
