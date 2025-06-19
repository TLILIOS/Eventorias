//
//  KeychainService.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 03/06/2025.
//

import Foundation
import Security

// Import the protocol from the Protocols directory
import Foundation
import Security

/// Service pour gérer le stockage sécurisé des données dans le Keychain
final class KeychainService: KeychainServiceProtocol {
    
    // MARK: - Private Properties
    
    private let service: String
    
    // MARK: - Initialization
    
    init(service: String = Bundle.main.bundleIdentifier ?? "com.eventorias.app") {
        self.service = service
    }
    
    // MARK: - Public Methods
    
    /// Sauvegarde une donnée dans le Keychain
    func save(_ data: String, for account: String) -> Bool {
        // Supprimer d'abord toute donnée existante
        delete(for: account)
        
        guard let data = data.data(using: .utf8) else {
            return false
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Récupère une donnée depuis le Keychain
    func retrieve(for account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess, 
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    /// Supprime une donnée du Keychain
    func delete(for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Vérifie si une donnée existe dans le Keychain
    func exists(for account: String) -> Bool {
        return retrieve(for: account) != nil
    }
}
