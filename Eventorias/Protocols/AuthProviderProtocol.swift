//
//  AuthProviderProtocol.swift
//  Eventorias
//
//  Created on 23/06/2025.
//

import Foundation
import FirebaseAuth

/// Protocole définissant les opérations d'authentification utilisateur
public protocol AuthProviderProtocol {
    /// L'utilisateur actuellement connecté, ou nil si aucun
    var currentUser: UserProtocol? { get }
    
    /// Connecte un utilisateur avec son email et mot de passe
    /// - Parameters:
    ///   - email: Adresse email
    ///   - password: Mot de passe
    /// - Returns: Résultat de l'authentification
    /// - Throws: Erreur si la connexion échoue
    func signIn(withEmail email: String, password: String) async throws -> AuthDataResultProtocol
    
    /// Crée un nouvel utilisateur avec email et mot de passe
    /// - Parameters:
    ///   - email: Adresse email
    ///   - password: Mot de passe
    /// - Returns: Résultat de la création de compte
    /// - Throws: Erreur si la création échoue
    func createUser(withEmail email: String, password: String) async throws -> AuthDataResultProtocol
    
    /// Déconnecte l'utilisateur actuel
    /// - Throws: Erreur si la déconnexion échoue
    func signOut() throws
    
    /// Récupère l'utilisateur actuellement connecté
    /// - Returns: L'utilisateur ou nil si aucun
    func getCurrentUser() -> UserProtocol?
    
    /// Vérifie si un utilisateur est connecté
    /// - Returns: true si un utilisateur est connecté, sinon false
    func isUserAuthenticated() -> Bool
    
    /// Met à jour le profil de l'utilisateur connecté
    /// - Parameters:
    ///   - displayName: Nom d'affichage à mettre à jour (optionnel)
    ///   - photoURL: URL de la photo de profil à mettre à jour (optionnel)
    /// - Throws: Erreur si la mise à jour échoue
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws
}

/// Protocole pour abstraire les données utilisateur
public protocol UserProtocol {
    var uid: String { get }
    var email: String? { get }
    var displayName: String? { get }
    var photoURL: URL? { get }
    var isAnonymous: Bool { get }
    var isEmailVerified: Bool { get }
    
    /// Méthode pour obtenir l'URL de la photo de profil (contourne les limitations des protocoles existentiels)
    func getPhotoURL() -> URL?
}

/// Protocole pour abstraire les résultats d'authentification
public protocol AuthDataResultProtocol {
    var user: UserProtocol { get }
    var additionalUserInfo: [String: Any]? { get }
}

// Note: Les implémentations des adaptateurs ont été déplacées vers FirebaseAdapters.swift

// Extension pour convertir AdditionalUserInfo en dictionnaire
extension AdditionalUserInfo {
    var dictionaryValue: [String: Any] {
        var result: [String: Any] = [:]
        result["isNewUser"] = isNewUser
        result["providerId"] = providerID
        if let username = username {
            result["username"] = username
        }
        if let profile = profile {
            result["profile"] = profile
        }
        return result
    }
}
