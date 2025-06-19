//
//  KeychainServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation

/// Protocole définissant les opérations de stockage sécurisé dans le Keychain
protocol KeychainServiceProtocol {
    /// Sauvegarde une donnée dans le Keychain
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Returns: true si la sauvegarde a réussi, false sinon
    func save(_ data: String, for account: String) -> Bool
    
    /// Récupère une donnée depuis le Keychain
    /// - Parameter account: L'identifiant du compte/clé
    /// - Returns: La donnée stockée ou nil si non trouvée
    func retrieve(for account: String) -> String?
    
    /// Supprime une donnée du Keychain
    /// - Parameter account: L'identifiant du compte/clé à supprimer
    /// - Returns: true si la suppression a réussi, false sinon
    func delete(for account: String) -> Bool
    
    /// Vérifie si une donnée existe dans le Keychain
    /// - Parameter account: L'identifiant du compte/clé à vérifier
    /// - Returns: true si la donnée existe, false sinon
    func exists(for account: String) -> Bool
}
