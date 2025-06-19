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

// Mock amélioré pour les tests
class MockAuthenticationService: AuthenticationServiceProtocol {
    // Propriétés existantes
    var mockUser: MockUser? = nil
    var currentUser: UserProtocol? { return mockUser }
    var currentUserDisplayName: String = "Test User"
    var currentUserEmail: String? = "test@example.com"
    
    // Ajout de propriétés de tracking pour les tests
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var getCurrentUserCalled = false
    var isUserAuthenticatedCalled = false
    var isValidEmailCalled = false
    var isValidPasswordCalled = false
    
    // Paramètres stockés pour vérification
    var lastEmailUsed: String? = nil
    var lastPasswordUsed: String? = nil
    
    // Configuration pour simuler des réponses
    var shouldThrowOnSignIn = false
    var shouldThrowOnSignUp = false
    var shouldThrowOnSignOut = false
    var returnAuthenticationStatus = false
    var errorToThrow: Error? = nil
    
    init(userDisplayName: String = "Test User", userEmail: String = "test@example.com") {
        self.currentUserDisplayName = userDisplayName
        self.currentUserEmail = userEmail
        self.mockUser = MockUser(uid: "test-uid", email: userEmail, displayName: userDisplayName)
    }
    
    // Implémentation des méthodes requises
    func signIn(email: String, password: String) async throws -> AuthDataResultProtocol {
        signInCalled = true
        lastEmailUsed = email
        lastPasswordUsed = password
        
        if shouldThrowOnSignIn {
            throw errorToThrow ?? NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock auth error"])
        }
        
        // Créer et retourner un faux AuthDataResultProtocol
        self.mockUser = MockUser(uid: "signed-in-user", email: email, displayName: "Signed In User")
        return MockAuthDataResult(user: self.mockUser!)
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResultProtocol {
        signUpCalled = true
        lastEmailUsed = email
        lastPasswordUsed = password
        
        if shouldThrowOnSignUp {
            throw errorToThrow ?? NSError(domain: "MockAuthError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Mock signup error"])
        }
        
        self.mockUser = MockUser(uid: "signed-up-user", email: email, displayName: "New User")
        return MockAuthDataResult(user: self.mockUser!)
    }
    
    func signOut() throws {
        signOutCalled = true
        if shouldThrowOnSignOut {
            throw errorToThrow ?? NSError(domain: "MockAuthError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Mock signout error"])
        }
        self.mockUser = nil
    }
    
    func getCurrentUser() -> UserProtocol? {
        getCurrentUserCalled = true
        return mockUser
    }
    
    func isUserAuthenticated() -> Bool {
        isUserAuthenticatedCalled = true
        return returnAuthenticationStatus
    }
    
    func isValidEmail(_ email: String) -> Bool {
        isValidEmailCalled = true
        lastEmailUsed = email
        return email.contains("@")
    }
    
    func isValidPassword(_ password: String) -> Bool {
        isValidPasswordCalled = true
        lastPasswordUsed = password
        return password.count >= 6
    }
    
    // Méthodes pour faciliter les tests
    func configureForSuccess() {
        shouldThrowOnSignIn = false
        shouldThrowOnSignUp = false
        shouldThrowOnSignOut = false
        returnAuthenticationStatus = true
        errorToThrow = nil
    }
    
    func configureForError(error: Error) {
        shouldThrowOnSignIn = true
        shouldThrowOnSignUp = true
        shouldThrowOnSignOut = true
        returnAuthenticationStatus = false
        errorToThrow = error
    }
    
    func reset() {
        signInCalled = false
        signUpCalled = false
        signOutCalled = false
        getCurrentUserCalled = false
        isUserAuthenticatedCalled = false
        isValidEmailCalled = false
        isValidPasswordCalled = false
        lastEmailUsed = nil
        lastPasswordUsed = nil
    }
}

// Protocol for mocking User properties and methods needed for testing
protocol UserProtocol {
    var uid: String { get }
    var email: String? { get }
    var displayName: String? { get }
}

// Protocol for mocking AuthDataResult properties and methods needed for testing
protocol AuthDataResultProtocol {
    var user: UserProtocol { get }
}

// Extend Firebase User to conform to our protocol
extension User: UserProtocol {}

// Use an adapter class to wrap Firebase's AuthDataResult
class FirebaseAuthDataResultAdapter: AuthDataResultProtocol {
    private let authDataResult: AuthDataResult
    
    init(_ authDataResult: AuthDataResult) {
        self.authDataResult = authDataResult
    }
    
    var user: UserProtocol {
        return authDataResult.user
    }
}


// Mock implementation of UserProtocol for testing
class MockUser: UserProtocol {
    let uid: String
    let email: String?
    let displayName: String?
    
    init(uid: String = "mock-user-id", email: String? = "mock@example.com", displayName: String? = "Mock User") {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
}

// Mock implementation of AuthDataResultProtocol for testing
class MockAuthDataResult: AuthDataResultProtocol {
    let user: UserProtocol
    
    init(user: UserProtocol = MockUser()) {
        self.user = user
    }
}
