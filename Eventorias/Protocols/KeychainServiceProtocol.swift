//
//  KeychainServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation

/// Types d'erreurs pouvant être renvoyées par les opérations Keychain
public enum KeychainError: Error, Equatable {
    /// Erreur lors de la création d'un item dans le Keychain
    case creationFailed(OSStatus)
    /// Erreur lors de la récupération d'un item du Keychain
    case retrievalFailed(OSStatus)
    /// Erreur lors de la mise à jour d'un item dans le Keychain
    case updateFailed(OSStatus)
    /// Erreur lors de la suppression d'un item du Keychain
    case deletionFailed(OSStatus)
    /// Erreur de conversion des données
    case dataConversionFailed
    /// Item non trouvé dans le Keychain
    case itemNotFound
    /// Erreur avec un message personnalisé
    case unexpectedError(String)
    
    /// Description lisible de l'erreur
    var localizedDescription: String {
        switch self {
        case .creationFailed(let status):
            return "Échec de la création de l'élément dans le Keychain. Code: \(status)"
        case .retrievalFailed(let status):
            return "Échec de la récupération depuis le Keychain. Code: \(status)"
        case .updateFailed(let status):
            return "Échec de la mise à jour de l'élément dans le Keychain. Code: \(status)"
        case .deletionFailed(let status):
            return "Échec de la suppression de l'élément du Keychain. Code: \(status)"
        case .dataConversionFailed:
            return "Échec de la conversion des données"
        case .itemNotFound:
            return "Élément non trouvé dans le Keychain"
        case .unexpectedError(let message):
            return "Erreur inattendue: \(message)"
        }
    }
}

/// Protocole définissant les opérations de stockage sécurisé dans le Keychain
public protocol KeychainServiceProtocol {
    /// Le service utilisé pour les requêtes Keychain
    var service: String { get }
    
    /// Sauvegarde une donnée dans le Keychain
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Throws: KeychainError en cas d'échec
    func save(_ data: String, for account: String) throws
    
    /// Met à jour une donnée dans le Keychain si elle existe, sinon la crée
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Throws: KeychainError en cas d'échec
    func update(_ data: String, for account: String) throws
    
    /// Récupère une donnée depuis le Keychain
    /// - Parameter account: L'identifiant du compte/clé
    /// - Returns: La donnée stockée
    /// - Throws: KeychainError si non trouvée ou erreur
    func retrieve(for account: String) throws -> String
    
    /// Supprime une donnée du Keychain
    /// - Parameter account: L'identifiant du compte/clé à supprimer
    /// - Throws: KeychainError en cas d'échec
    func delete(for account: String) throws
    
    /// Vérifie si une donnée existe dans le Keychain
    /// - Parameter account: L'identifiant du compte/clé à vérifier
    /// - Returns: true si la donnée existe, false sinon
    func exists(for account: String) -> Bool
}
