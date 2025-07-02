import Foundation
import XCTest
@testable import Eventorias
@MainActor
/// Mock pour AuthenticationServiceProtocol facilitant les tests unitaires
final class MockAuthenticationService: AuthenticationServiceProtocol {
    var currentUserMock: UserProtocol?
    var currentUserDisplayNameMock: String = "Utilisateur Test"
    var currentUserEmailMock: String? = "test@exemple.com"
    
    // Tracking des appels pour la vérification dans les tests
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var getCurrentUserCalled = false
    var isUserAuthenticatedCalled = false
    var isValidEmailCalled = false
    var isValidPasswordCalled = false
    var updateUserProfileCalled = false
    var deleteAccountCalled = false
    var resetPasswordCalled = false
    
    // Variables pour contrôler le comportement des fonctions
    var shouldThrowError = false
    var mockError: Error = NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée"])
    var isUserAuthenticatedReturnValue = false
    
    var currentUser: UserProtocol? {
        getCurrentUserCalled = true
        return currentUserMock
    }
    
    var currentUserDisplayName: String {
        return currentUserDisplayNameMock
    }
    
    var currentUserEmail: String? {
        return currentUserEmailMock
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResultProtocol {
        signInCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Crée un utilisateur mock pour le test
        let mockUser = MockUser(uid: "test-uid", email: email, displayName: "Test User")
        currentUserMock = mockUser
        
        return MockAuthDataResult(user: mockUser)
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResultProtocol {
        signUpCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        let mockUser = MockUser(uid: "new-test-uid", email: email, displayName: "Nouvel Utilisateur")
        currentUserMock = mockUser
        
        return MockAuthDataResult(user: mockUser)
    }
    
    func signOut() throws {
        signOutCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        currentUserMock = nil
    }
    
    func getCurrentUser() -> UserProtocol? {
        getCurrentUserCalled = true
        return currentUserMock
    }
    
    func isUserAuthenticated() -> Bool {
        isUserAuthenticatedCalled = true
        return isUserAuthenticatedReturnValue
    }
    
    func isValidEmail(_ email: String) -> Bool {
        isValidEmailCalled = true
        return email.contains("@") && email.contains(".")
    }
    
    func isValidPassword(_ password: String) -> Bool {
        isValidPasswordCalled = true
        return password.count >= 6
    }
    
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        updateUserProfileCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        if let name = displayName {
            currentUserDisplayNameMock = name
        }
    }
    
    func deleteAccount() async throws {
        deleteAccountCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        currentUserMock = nil
    }
    
    func resetPassword(email: String) async throws {
        resetPasswordCalled = true
        
        if shouldThrowError {
            throw mockError
        }
    }
}

/// Mock pour UserProtocol
final class MockUser: UserProtocol {
    var uid: String
    var email: String?
    var displayName: String?
    var photoURL: URL?
    var isAnonymous: Bool
    var isEmailVerified: Bool
    
    init(uid: String, email: String? = nil, displayName: String? = nil, photoURL: URL? = nil, isAnonymous: Bool = false, isEmailVerified: Bool = true) {
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

/// Mock pour AuthDataResultProtocol
final class MockAuthDataResult: AuthDataResultProtocol {
    var user: UserProtocol
    var additionalUserInfo: [String: Any]?
    
    init(user: UserProtocol, additionalUserInfo: [String: Any]? = nil) {
        self.user = user
        self.additionalUserInfo = additionalUserInfo
    }
}
