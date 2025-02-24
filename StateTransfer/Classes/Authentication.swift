//
//  Authenticaction.swift
//  StateTransfer
//
//  Created by Holger Krupp on 24.02.25.
//
import Security
import Foundation

struct Authentication: Equatable{
    var username: String = ""
    var password: String = ""
    var active: Bool = false
    var type: AuthenticationMethod = .basic
    
    static func == (lhs: Authentication, rhs: Authentication) -> Bool {
           return lhs.username == rhs.username &&
                  lhs.password == rhs.password &&
                  lhs.active == rhs.active &&
                  lhs.type == rhs.type
       }
    
}

enum AuthenticationMethod{
    case basic
}



struct KeychainManager {
    
    static func saveCredentials(_ credentials: Authentication, server: String) {
        
        print("Trying to save credentials for \(server)")
        
        guard let passwordData = credentials.password.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecAttrAccount as String: credentials.username,
            kSecValueData as String: passwordData
        ]
        
        // Delete existing entry (if any) before adding new one
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            print("Error saving credentials: \(status)")
        }
    }

    static func getCredentials(for server: String) -> Authentication? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let existingItem = item as? [String: Any],
              let username = existingItem[kSecAttrAccount as String] as? String,
              let passwordData = existingItem[kSecValueData as String] as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            print("No credentials found for \(server)")
            return nil
        }
        
        return Authentication(username: username, password: password, active: true, type: .basic)
    }

    static func deleteCredentials(for server: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: server
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        if status != errSecSuccess {
            print("Error deleting credentials: \(status)")
        }
    }
}
