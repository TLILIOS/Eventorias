//
// AuthenticationService.swift
// Eventorias
//
// Created by TLiLi Hamdi on 27/05/2025.
//

import Foundation
import Firebase
import FirebaseAuth

/// Service de gestion de l'authentification Firebase
final class AuthenticationService {
    
    // MARK: - Authentication Methods
    
    /// Connecte un utilisateur avec email et mot de passe
    /// - Parameters:
    ///   - email: L'adresse email de l'utilisateur
    ///   - password: Le mot de passe de l'utilisateur
    /// - Returns: Résultat de l'authentification
    /// - Throws: Erreur Firebase Auth
    func signIn(email: String, password: String) async throws -> AuthDataResult {
        return try await Auth.auth().signIn(withEmail: email, password: password)
    }
    
    /// Crée un nouveau compte utilisateur
    /// - Parameters:
    ///   - email: L'adresse email pour le nouveau compte
    ///   - password: Le mot de passe pour le nouveau compte
    /// - Returns: Résultat de la création de compte
    /// - Throws: Erreur Firebase Auth
    func signUp(email: String, password: String) async throws -> AuthDataResult {
        return try await Auth.auth().createUser(withEmail: email, password: password)
    }
    
    /// Déconnecte l'utilisateur actuel
    /// - Throws: Erreur Firebase Auth
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    /// Récupère l'utilisateur actuellement connecté
    /// - Returns: L'utilisateur actuel ou nil
    func getCurrentUser() -> User? {
        return Auth.auth().currentUser
    }
    
    /// Vérifie si un utilisateur est actuellement authentifié
    /// - Returns: true si un utilisateur est connecté, false sinon
    func isUserAuthenticated() -> Bool {
        return Auth.auth().currentUser != nil
    }
    
    /// Valide le format d'un email
    /// - Parameter email: L'email à valider
    /// - Returns: true si l'email est valide, false sinon
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    /// Valide la force d'un mot de passe
    /// - Parameter password: Le mot de passe à valider
    /// - Returns: true si le mot de passe est suffisamment fort, false sinon
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
}
