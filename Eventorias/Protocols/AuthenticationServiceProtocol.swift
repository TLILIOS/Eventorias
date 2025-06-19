//
//  AuthenticationServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 17/06/2025.
//

import Foundation
import FirebaseAuth

/// Protocole définissant les opérations d'authentification
protocol AuthenticationServiceProtocol {
    /// L'utilisateur actuellement connecté
    var currentUser: UserProtocol? { get }
    
    /// Le nom d'affichage de l'utilisateur actuel
    var currentUserDisplayName: String { get }
    
    /// L'email de l'utilisateur actuel
    var currentUserEmail: String? { get }
    
    /// Connecte un utilisateur avec email et mot de passe
    /// - Parameters:
    ///   - email: L'adresse email de l'utilisateur
    ///   - password: Le mot de passe de l'utilisateur
    /// - Returns: Résultat de l'authentification
    /// - Throws: Erreur d'authentification
    func signIn(email: String, password: String) async throws -> AuthDataResultProtocol
    
    /// Crée un nouveau compte utilisateur
    /// - Parameters:
    ///   - email: L'adresse email pour le nouveau compte
    ///   - password: Le mot de passe pour le nouveau compte
    /// - Returns: Résultat de la création de compte
    /// - Throws: Erreur d'authentification
    func signUp(email: String, password: String) async throws -> AuthDataResultProtocol
    
    /// Déconnecte l'utilisateur actuel
    /// - Throws: Erreur d'authentification
    func signOut() throws
    
    /// Récupère l'utilisateur actuellement connecté
    /// - Returns: L'utilisateur actuel ou nil
    func getCurrentUser() -> UserProtocol?
    
    /// Vérifie si un utilisateur est actuellement authentifié
    /// - Returns: true si un utilisateur est connecté, false sinon
    func isUserAuthenticated() -> Bool
    
    /// Valide le format d'un email
    /// - Parameter email: L'email à valider
    /// - Returns: true si l'email est valide, false sinon
    func isValidEmail(_ email: String) -> Bool
    
    /// Valide la force d'un mot de passe
    /// - Parameter password: Le mot de passe à valider
    /// - Returns: true si le mot de passe est suffisamment fort, false sinon
    func isValidPassword(_ password: String) -> Bool
    
    /// Met à jour le profil utilisateur
    /// - Parameters:
    ///   - displayName: Nouveau nom d'affichage (optionnel)
    ///   - photoURL: URL de la photo de profil (optionnel)
    /// - Throws: Erreur d'authentification
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws
}



// Note: Les types UserProtocol et AuthDataResultProtocol sont maintenant définis dans FirebaseAdapters.swift
// Les classes MockUser et MockAuthDataResult sont déplacées vers les fichiers de test appropriés
