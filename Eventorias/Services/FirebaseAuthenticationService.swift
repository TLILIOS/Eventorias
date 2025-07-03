//
//  FirebaseAuthenticationService.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseAuth

/// Implémentation Firebase du service d'authentification
final class FirebaseAuthenticationService: AuthenticationServiceProtocol, AuthServiceInjectable {
    // Fournisseur d'authentification - permet l'injection de dépendances pour les tests
    private var authProvider: AuthProviderProtocol = FirebaseAuthAdapter.fromSharedAuth()
    
    /// Permet d'injecter un fournisseur d'authentification alternatif (pour les tests)
    func injectAuthProvider(_ provider: AuthProviderProtocol) {
        self.authProvider = provider
    }
    var currentUser: UserProtocol? {
        return authProvider.currentUser
    }
    
    var currentUserDisplayName: String {
        authProvider.currentUser?.displayName ?? "Utilisateur anonyme"
    }
    
    var currentUserEmail: String? {
        authProvider.currentUser?.email
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResultProtocol {
        return try await authProvider.signIn(withEmail: email, password: password)
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResultProtocol {
        return try await authProvider.createUser(withEmail: email, password: password)
    }
    
    func signOut() throws {
        try authProvider.signOut()
    }
    
    func getCurrentUser() -> UserProtocol? {
        return authProvider.getCurrentUser()
    }
    
    func isUserAuthenticated() -> Bool {
        return authProvider.isUserAuthenticated()
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{1,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    func isValidPassword(_ password: String) -> Bool {
        return password.count >= 6
    }
    
    /// Met à jour le profil utilisateur
    /// - Parameters:
    ///   - displayName: Nouveau nom d'affichage (optionnel)
    ///   - photoURL: URL de la photo de profil (optionnel)
    /// - Throws: Erreur d'authentification
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        guard currentUser != nil else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }
        
        try await authProvider.updateUserProfile(displayName: displayName, photoURL: photoURL)
    }
    
    /// Supprime le compte utilisateur actuellement connecté
    /// - Throws: Erreur d'authentification (par exemple, ré-authentification requise)
    func deleteAccount() async throws {
        guard let _ = authProvider.currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }
        
        // Note: Cette méthode n'est pas dans AuthProviderProtocol
        // Dans une implémentation réelle, nous devrions l'ajouter au protocole
        // Pour l'instant, nous utilisons directement l'API Firebase
        guard let firebaseUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }
        
        try await firebaseUser.delete()
    }
    
    /// Envoie un email de réinitialisation de mot de passe
    /// - Parameter email: L'adresse email pour réinitialiser le mot de passe
    /// - Throws: Erreur d'authentification
    func resetPassword(email: String) async throws {
        // Note: Cette méthode n'est pas dans AuthProviderProtocol
        // Dans une implémentation réelle, nous devrions l'ajouter au protocole
        // Pour l'instant, nous utilisons directement l'API Firebase
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
