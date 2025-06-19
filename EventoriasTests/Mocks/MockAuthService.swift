//
// MockAuthService.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import Foundation
import Firebase
import FirebaseAuth
@testable import Eventorias

// Utilisation des protocoles définis dans l'application principale

// Classes Mock
class MockUser: UserProtocol {
    let uid: String
    let email: String?
    let displayName: String?
    let photoURL: URL?
    let isAnonymous: Bool
    let isEmailVerified: Bool
    
    init(uid: String = "mock-uid",
         email: String? = "mock@example.com",
         displayName: String? = "Mock User",
         photoURL: URL? = nil,
         isAnonymous: Bool = false,
         isEmailVerified: Bool = true) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isAnonymous = isAnonymous
        self.isEmailVerified = isEmailVerified
    }
    
    func getPhotoURL() -> URL? {
        return photoURL
    }
}

class MockAuthDataResult: AuthDataResultProtocol {
    let user: UserProtocol
    
    init(user: UserProtocol = MockUser()) {
        self.user = user
    }
}

// Extension on AuthDataResult to create a mock instance for testing purposes
extension AuthDataResult {
    static var mock: AuthDataResult {
        // This is a hacky way to create a mock for testing only
        // It's a dummy object that will never be used for its actual properties
        // We're just using it as a placeholder for successful auth operations
        unsafeBitCast(NSObject(), to: AuthDataResult.self)
    }
}

class MockAuthService: AuthenticationServiceProtocol {
    // MARK: - Tracking properties
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var getCurrentUserCalled = false
    var isUserAuthenticatedCalled = false
    var isValidEmailCalled = false
    var isValidPasswordCalled = false
    
    // Track the last email and password used
    var lastEmail: String?
    var lastPassword: String?
    
    // MARK: - Mock responses
    var mockAuthResult: AuthDataResultProtocol?
    var mockUser: UserProtocol?
    var mockIsAuthenticated = false
    var mockError: Error?
    
    // MARK: - Controls behavior for tests
    var shouldThrowOnSuccess = true  // Set to false for AuthenticationViewModel tests
    
    // MARK: - Reset functionality
    /// Réinitialise tous les états du mock entre les tests
    func reset() {
        // Reset tracking properties
        signInCalled = false
        signUpCalled = false
        signOutCalled = false
        getCurrentUserCalled = false
        isUserAuthenticatedCalled = false
        isValidEmailCalled = false
        isValidPasswordCalled = false
        
        // Reset tracked values
        lastEmail = nil
        lastPassword = nil
        
        // Reset mock responses
        mockAuthResult = nil
        mockUser = nil
        mockIsAuthenticated = false
        mockError = nil
        
        // Reset behavior controls
        shouldThrowOnSuccess = true
    }
    
    /// Configure le mock pour les tests de succès (AuthenticationViewModel)
    func configureForViewModelTests() {
        reset()
        shouldThrowOnSuccess = false
    }
    
    /// Configure le mock pour les tests de service (AuthenticationService)
    func configureForServiceTests() {
        reset()
        shouldThrowOnSuccess = true
    }
    
    /// Configure une erreur spécifique pour les tests d'erreur
    func configureError(_ error: Error) {
        reset()
        mockError = error
    }
    
    /// Configure un état d'authentification spécifique
    func configureAuthState(isAuthenticated: Bool) {
        mockIsAuthenticated = isAuthenticated
    }
    
    // MARK: - Mock functions - override les méthodes d'AuthenticationService
    override func signIn(email: String, password: String) async throws -> AuthDataResult {
        signInCalled = true
        self.lastEmail = email
        self.lastPassword = password
        
        // If there's a specific error set, throw that
        if let error = mockError {
            throw error
        }
        
        // For AuthenticationServiceTests, throw a mock error
        if shouldThrowOnSuccess {
            let mockError = NSError(domain: "MockAuthService", code: 999,
                                  userInfo: [NSLocalizedDescriptionKey: "This is a mock implementation"])
            throw mockError
        }
        
        // For AuthenticationViewModelTests, update authentication state and return mock result
        mockIsAuthenticated = true
        return AuthDataResult.mock
    }
    
    override func signUp(email: String, password: String) async throws -> AuthDataResult {
        signUpCalled = true
        self.lastEmail = email
        self.lastPassword = password
        
        // If there's a specific error set, throw that
        if let error = mockError {
            throw error
        }
        
        // For AuthenticationServiceTests, throw a mock error
        if shouldThrowOnSuccess {
            let mockError = NSError(domain: "MockAuthService", code: 999,
                                  userInfo: [NSLocalizedDescriptionKey: "This is a mock implementation"])
            throw mockError
        }
        
        // For AuthenticationViewModelTests, update authentication state and return mock result
        mockIsAuthenticated = true
        return AuthDataResult.mock
    }
    
    override func signOut() throws {
        signOutCalled = true
        mockIsAuthenticated = false  // Reset auth state on sign out
        if let error = mockError {
            throw error
        }
    }
    
    override func getCurrentUser() -> User? {
        getCurrentUserCalled = true
        // Nous ne pouvons pas convertir UserProtocol en User, donc nous retournons nil
        return nil
    }
    
    override func isUserAuthenticated() -> Bool {
        isUserAuthenticatedCalled = true
        return mockIsAuthenticated
    }
    
    override func isValidEmail(_ email: String) -> Bool {
        isValidEmailCalled = true
        
        // supporter les domaines d'une seule lettre et les caractères Unicode
        let emailRegex = "^[\\p{L}\\p{N}._%+-]+@[\\p{L}\\p{N}]([\\p{L}\\p{N}-]*[\\p{L}\\p{N}])?(?:\\.[\\p{L}\\p{N}]([\\p{L}\\p{N}-]*[\\p{L}\\p{N}])?)*\\.[\\p{L}]{1,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }


    
    override func isValidPassword(_ password: String) -> Bool {
        isValidPasswordCalled = true
        return password.count >= 6
    }
}

// MARK: - Extensions pour faciliter les tests
extension MockAuthService {
    /// Vérifie qu'aucune méthode n'a été appelée
    var hasNoMethodsCalled: Bool {
        return !signInCalled && !signUpCalled && !signOutCalled &&
               !getCurrentUserCalled && !isUserAuthenticatedCalled &&
               !isValidEmailCalled && !isValidPasswordCalled
    }
    
    /// Retourne le nombre total d'appels de méthodes
    var totalMethodCalls: Int {
        var count = 0
        if signInCalled { count += 1 }
        if signUpCalled { count += 1 }
        if signOutCalled { count += 1 }
        if getCurrentUserCalled { count += 1 }
        if isUserAuthenticatedCalled { count += 1 }
        if isValidEmailCalled { count += 1 }
        if isValidPasswordCalled { count += 1 }
        return count
    }
}
