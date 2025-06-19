//
//  FirebaseAuthenticationService.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseAuth

/// Implémentation Firebase du service d'authentification
final class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    var currentUser: UserProtocol? {
        if let user = Auth.auth().currentUser {
            return FirebaseUserAdapter(user)
        }
        return nil
    }
    
    var currentUserDisplayName: String {
        Auth.auth().currentUser?.displayName ?? "Utilisateur anonyme"
    }
    
    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResultProtocol {
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return FirebaseAuthDataResultAdapter(result)
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResultProtocol {
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return FirebaseAuthDataResultAdapter(result)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
    }
    
    func getCurrentUser() -> UserProtocol? {
        if let user = Auth.auth().currentUser {
            return FirebaseUserAdapter(user)
        }
        return nil
    }
    
    func isUserAuthenticated() -> Bool {
        return Auth.auth().currentUser != nil
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
        guard let _ = currentUser, let firebaseUser = Auth.auth().currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }
        
        let changeRequest = firebaseUser.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
    }
}
