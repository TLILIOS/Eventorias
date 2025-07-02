//
//  FirebaseAuthProvider.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 21/06/2025.
//

import Foundation
import FirebaseAuth

/// Implémentation réelle du fournisseur d'authentification Firebase
class FirebaseAuthProvider: AuthProviderProtocol {
    // Initialisation paresseuse de Auth pour éviter l'appel avant FirebaseApp.configure()
    private lazy var auth = Auth.auth()
    var currentUser: UserProtocol? {
        if let user = auth.currentUser {
            return FirebaseUserAdapter(user)
        }
        return nil
    }
    
    func signIn(withEmail email: String, password: String) async throws -> AuthDataResultProtocol {
        let result = try await auth.signIn(withEmail: email, password: password)
        return FirebaseAuthDataResultAdapter(result)
    }
    
    func createUser(withEmail email: String, password: String) async throws -> AuthDataResultProtocol {
        let result = try await auth.createUser(withEmail: email, password: password)
        return FirebaseAuthDataResultAdapter(result)
    }
    
    func signOut() throws {
        try auth.signOut()
    }
    
    func getCurrentUser() -> UserProtocol? {
        if let user = auth.currentUser {
            return FirebaseUserAdapter(user)
        }
        return nil
    }
    
    func isUserAuthenticated() -> Bool {
        return auth.currentUser != nil
    }
    
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else {
            throw NSError(domain: "AuthError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Aucun utilisateur connecté"])
        }
        
        let changeRequest = user.createProfileChangeRequest()
        
        if let displayName = displayName {
            changeRequest.displayName = displayName
        }
        
        if let photoURL = photoURL {
            changeRequest.photoURL = photoURL
        }
        
        try await changeRequest.commitChanges()
    }
}
