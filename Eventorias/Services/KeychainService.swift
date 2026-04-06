//
//  KeychainService.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 03/06/2025.
//

import Foundation
import Security

/// Service pour gérer le stockage sécurisé des données dans le Keychain
final class KeychainService: KeychainServiceProtocol {
    
    // MARK: - Properties
    
    /// Le service utilisé pour les requêtes Keychain
    public let service: String
    
    /// Les flags d'accessibilité du Keychain
    private let accessibility: CFString
    
    /// Mode debug pour journalisation
    private let debug: Bool
    
    // MARK: - Initialization
    
    /// Initialise un nouveau service Keychain
    /// - Parameters:
    ///   - service: Identifiant du service (généralement bundleID)
    ///   - accessibility: Règles d'accessibilité des données
    ///   - debug: Activer la journalisation de débogage
    init(
        service: String = Bundle.main.bundleIdentifier ?? "com.eventorias.app",
        accessibility: CFString = kSecAttrAccessibleAfterFirstUnlock,
        debug: Bool = false
    ) {
        self.service = service
        self.accessibility = accessibility
        self.debug = debug
        
        if debug {
            print("🔐 KeychainService initialisé avec service: \(service)")
        }
    }
    
    // MARK: - Public Methods (Protocol Implementation)
    
    /// Sauvegarde une donnée dans le Keychain
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Throws: KeychainError en cas d'échec
    public func save(_ data: String, for account: String) throws {
        // Si l'entrée existe déjà, on la supprime
        try? delete(for: account)
        
        guard let encodedData = data.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: encodedData,
            kSecAttrAccessible as String: accessibility
        ]
        
        log("Sauvegarde des données pour le compte: \(account)")
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            log("❌ Échec de la sauvegarde pour le compte: \(account), code: \(status)")
            throw KeychainError.creationFailed(status)
        }
        
        log("✅ Données sauvegardées avec succès pour le compte: \(account)")
    }
    
    /// Met à jour une donnée dans le Keychain si elle existe, sinon la crée
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Throws: KeychainError en cas d'échec
    public func update(_ data: String, for account: String) throws {
        guard let encodedData = data.data(using: .utf8) else {
            throw KeychainError.dataConversionFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: encodedData,
            kSecAttrAccessible as String: accessibility
        ]
        
        log("Mise à jour des données pour le compte: \(account)")
        
        // Tenter la mise à jour
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        // Si l'entrée n'existe pas, la créer
        if status == errSecItemNotFound {
            log("Item non trouvé, tentative de création pour: \(account)")
            try save(data, for: account)
            return
        }
        
        guard status == errSecSuccess else {
            log("❌ Échec de la mise à jour pour le compte: \(account), code: \(status)")
            throw KeychainError.updateFailed(status)
        }
        
        log("✅ Données mises à jour avec succès pour le compte: \(account)")
    }
    
    /// Récupère une donnée depuis le Keychain
    /// - Parameter account: L'identifiant du compte/clé
    /// - Returns: La donnée stockée
    /// - Throws: KeychainError si non trouvée ou erreur
    public func retrieve(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnData as String: true
        ]
        
        log("Récupération des données pour le compte: \(account)")
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                log("❌ Aucune donnée trouvée pour le compte: \(account)")
                throw KeychainError.itemNotFound
            } else {
                log("❌ Échec de la récupération pour le compte: \(account), code: \(status)")
                throw KeychainError.retrievalFailed(status)
            }
        }
        
        guard let data = result as? Data else {
            log("❌ Données récupérées invalides pour le compte: \(account)")
            throw KeychainError.dataConversionFailed
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            log("❌ Impossible de convertir les données en chaîne pour le compte: \(account)")
            throw KeychainError.dataConversionFailed
        }
        
        log("✅ Données récupérées avec succès pour le compte: \(account)")
        return string
    }
    
    /// Supprime une donnée du Keychain
    /// - Parameter account: L'identifiant du compte/clé à supprimer
    /// - Throws: KeychainError en cas d'échec
    public func delete(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        
        log("Suppression des données pour le compte: \(account)")
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Ne pas lever d'erreur si l'élément n'existe pas
        if status == errSecItemNotFound {
            log("⚠️ Aucune donnée à supprimer pour le compte: \(account)")
            return
        }
        
        guard status == errSecSuccess else {
            log("❌ Échec de la suppression pour le compte: \(account), code: \(status)")
            throw KeychainError.deletionFailed(status)
        }
        
        log("✅ Données supprimées avec succès pour le compte: \(account)")
    }
    
    /// Vérifie si une donnée existe dans le Keychain
    /// - Parameter account: L'identifiant du compte/clé à vérifier
    /// - Returns: true si la donnée existe, false sinon
    public func exists(for account: String) -> Bool {
        do {
            _ = try retrieve(for: account)
            return true
        } catch {
            return false
        }
    }
    
    // MARK: - Private Methods
    
    /// Journalise un message si le mode debug est activé
    /// - Parameter message: Message à journaliser
    private func log(_ message: String) {
        if debug {
            print("🔐 KeychainService: \(message)")
        }
    }
}
