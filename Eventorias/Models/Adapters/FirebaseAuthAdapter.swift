//
//  FirebaseAuthAdapter.swift
//  Eventorias
//
//  Created on 02/07/2025.
//

import Foundation
import FirebaseAuth

/// Adaptateur qui fait conformer Auth.auth() au protocole AuthProviderProtocol
@MainActor
final class FirebaseAuthAdapter: AuthProviderProtocol {
    private let auth: Auth
    
    init(_ auth: Auth = Auth.auth()) {
        self.auth = auth
    }
    
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
        guard let firebaseUser = auth.currentUser else {
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

/// Extension pour ajouter un constructeur à partir de Auth
extension FirebaseAuthAdapter {
    static func fromSharedAuth() -> FirebaseAuthAdapter {
        return FirebaseAuthAdapter(Auth.auth())
    }
}
