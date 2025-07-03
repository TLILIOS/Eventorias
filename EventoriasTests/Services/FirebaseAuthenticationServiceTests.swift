//
//  FirebaseAuthenticationServiceTests.swift
//  EventoriasTests
//
//  Created on 02/07/2025.
//

import XCTest
import FirebaseAuth
@testable import Eventorias
@MainActor
final class FirebaseAuthenticationServiceTests: XCTestCase {
    
    // MARK: - Mocks
    
    /// Mock spécifique pour les tests d'authentification
    class AuthenticationTestMockUser: UserProtocol {
        var uid: String = "mock-user-id"
        var email: String? = "test@example.com"
        var displayName: String? = "Test User"
        var photoURL: URL? = URL(string: "https://example.com/photo.jpg")
        var isAnonymous: Bool = false
        var isEmailVerified: Bool = true
        
        func getPhotoURL() -> URL? {
            return photoURL
        }
    }
    
    /// Mock pour AuthDataResultProtocol
    class MockAuthDataResult: AuthDataResultProtocol {
        var user: UserProtocol
        var additionalUserInfo: [String: Any]?
        
        init(user: UserProtocol, additionalUserInfo: [String: Any]? = nil) {
            self.user = user
            self.additionalUserInfo = additionalUserInfo
        }
    }
    
    /// Mock pour FirebaseAuth
    class MockAuth {
        static var shared = MockAuth()
        
        var currentUser: AuthenticationTestMockUser?
        var signInCallback: ((String, String) async throws -> AuthDataResultProtocol)?
        var createUserCallback: ((String, String) async throws -> AuthDataResultProtocol)?
        var signOutCallback: (() throws -> Void)?
        var resetPasswordCallback: ((String) async throws -> Void)?
        var updateProfileCallback: ((inout MockAuth.ProfileChangeRequest) async throws -> Void)?
        var deleteAccountCallback: (() async throws -> Void)?
        
        func reset() {
            currentUser = nil
            signInCallback = nil
            createUserCallback = nil
            signOutCallback = nil
            resetPasswordCallback = nil
            updateProfileCallback = nil
            deleteAccountCallback = nil
        }
        
        class ProfileChangeRequest {
            var displayName: String?
            var photoURL: URL?
            var commitCallback: (() async throws -> Void)?
            
            func commit() async throws {
                if let commitCallback = commitCallback {
                    try await commitCallback()
                }
            }
        }
    }
    
    // MARK: - SUT
    
    private var sut: FirebaseAuthenticationService!
    private let mockAuth = FirebaseAuthenticationServiceTests.MockAuth.shared
    private let mockUser = AuthenticationTestMockUser()
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAuth.reset()
        sut = FirebaseAuthenticationService()
        
        // Injecter notre mock dans l'instance de test
        // (Nécessite de rendre la dépendance Auth injectable)
        if let serviceWithInjection = sut as? AuthServiceInjectable {
            serviceWithInjection.injectAuthProvider(MockAuthProvider())
        }
    }
    
    override func tearDown() {
        sut = nil
        mockAuth.reset()
        super.tearDown()
    }
    
    // MARK: - Tests for User Properties
    
    func testCurrentUser_whenUserLoggedIn_returnsUser() {
        // Given
        mockAuth.currentUser = mockUser
        
        // When
        let user = sut.currentUser
        
        // Then
        XCTAssertNotNil(user)
        XCTAssertEqual(user?.uid, mockUser.uid)
        XCTAssertEqual(user?.email, mockUser.email)
    }
    
    func testCurrentUser_whenNoUserLoggedIn_returnsNil() {
        // Given
        mockAuth.currentUser = nil
        
        // When
        let user = sut.currentUser
        
        // Then
        XCTAssertNil(user)
    }
    
    func testCurrentUserDisplayName_whenUserHasName_returnsName() {
        // Given
        mockAuth.currentUser = mockUser
        mockUser.displayName = "John Doe"
        
        // When
        let displayName = sut.currentUserDisplayName
        
        // Then
        XCTAssertEqual(displayName, "John Doe")
    }
    
    func testCurrentUserDisplayName_whenUserHasNoName_returnsDefaultName() {
        // Given
        mockAuth.currentUser = mockUser
        mockUser.displayName = nil
        
        // When
        let displayName = sut.currentUserDisplayName
        
        // Then
        XCTAssertEqual(displayName, "Utilisateur anonyme")
    }
    
    func testCurrentUserEmail_whenUserHasEmail_returnsEmail() {
        // Given
        mockAuth.currentUser = mockUser
        mockUser.email = "user@example.com"
        
        // When
        let email = sut.currentUserEmail
        
        // Then
        XCTAssertEqual(email, "user@example.com")
    }
    
    // MARK: - Tests for Authentication Methods
    
    func testSignIn_whenValidCredentials_returnsAuthDataResult() async throws {
        // Given
        let expectedResult = MockAuthDataResult(user: mockUser)
        mockAuth.signInCallback = { email, password in
            XCTAssertEqual(email, "test@example.com")
            XCTAssertEqual(password, "password123")
            return expectedResult
        }
        
        // When
        let result = try await sut.signIn(email: "test@example.com", password: "password123")
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual((result.user as? AuthenticationTestMockUser)?.uid, mockUser.uid)
    }
    
    func testSignIn_whenInvalidCredentials_throwsError() async {
        // Given
        mockAuth.signInCallback = { _, _ in
            throw NSError(domain: "auth", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid password"])
        }
        
        // When/Then
        do {
            _ = try await sut.signIn(email: "test@example.com", password: "wrong")
            XCTFail("Should have thrown an error")
        } catch {
            // Success - erreur attendue
        }
    }
    
    func testSignUp_whenValidCredentials_returnsAuthDataResult() async throws {
        // Given
        let expectedResult = MockAuthDataResult(user: mockUser)
        mockAuth.createUserCallback = { email, password in
            XCTAssertEqual(email, "new@example.com")
            XCTAssertEqual(password, "newpassword")
            return expectedResult
        }
        
        // When
        let result = try await sut.signUp(email: "new@example.com", password: "newpassword")
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual((result.user as? AuthenticationTestMockUser)?.uid, mockUser.uid)
    }
    
    func testSignOut_whenSuccessful_doesNotThrow() {
        // Given
        mockAuth.signOutCallback = { }
        
        // When/Then
        XCTAssertNoThrow(try sut.signOut())
    }
    
    func testSignOut_whenFailed_throwsError() {
        // Given
        mockAuth.signOutCallback = {
            throw NSError(domain: "auth", code: 2, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        }
        
        // When/Then
        XCTAssertThrowsError(try sut.signOut())
    }
    
    func testIsUserAuthenticated_whenUserLoggedIn_returnsTrue() {
        // Given
        mockAuth.currentUser = mockUser
        
        // When
        let isAuthenticated = sut.isUserAuthenticated()
        
        // Then
        XCTAssertTrue(isAuthenticated)
    }
    
    func testIsUserAuthenticated_whenNoUserLoggedIn_returnsFalse() {
        // Given
        mockAuth.currentUser = nil
        
        // When
        let isAuthenticated = sut.isUserAuthenticated()
        
        // Then
        XCTAssertFalse(isAuthenticated)
    }
    
    // MARK: - Tests for Validation Methods
    
    func testIsValidEmail_withValidEmails_returnsTrue() {
        // Test cases
        let validEmails = [
            "user@example.com",
            "user.name@example.co.uk",
            "user+tag@example.org"
        ]
        
        for email in validEmails {
            XCTAssertTrue(sut.isValidEmail(email), "Email should be valid: \(email)")
        }
    }
    
    func testIsValidEmail_withInvalidEmails_returnsFalse() {
        // Test cases
        let invalidEmails = [
            "",
            "userexample.com",
            "user@",
            "@example.com",
            "user@.com",
            "user@example."
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(sut.isValidEmail(email), "Email should be invalid: \(email)")
        }
    }
    
    func testIsValidPassword_whenValidLength_returnsTrue() {
        // When/Then
        XCTAssertTrue(sut.isValidPassword("123456"))
        XCTAssertTrue(sut.isValidPassword("abcdef"))
        XCTAssertTrue(sut.isValidPassword("a very long password"))
    }
    
    func testIsValidPassword_whenInvalidLength_returnsFalse() {
        // When/Then
        XCTAssertFalse(sut.isValidPassword(""))
        XCTAssertFalse(sut.isValidPassword("12345"))
        XCTAssertFalse(sut.isValidPassword("abc"))
    }
    
    // MARK: - Tests for Account Management
    
    func testUpdateUserProfile_whenUserLoggedIn_updatesProfile() async throws {
        // Given
        mockAuth.currentUser = mockUser
        var capturedDisplayName: String?
        var capturedPhotoURL: URL?
        
        mockAuth.updateProfileCallback = { request in
            capturedDisplayName = request.displayName
            capturedPhotoURL = request.photoURL
        }
        
        let newName = "New Name"
        let newPhotoURL = URL(string: "https://example.com/new.jpg")!
        
        // When
        try await sut.updateUserProfile(displayName: newName, photoURL: newPhotoURL)
        
        // Then
        XCTAssertEqual(capturedDisplayName, newName)
        XCTAssertEqual(capturedPhotoURL, newPhotoURL)
    }
    
    func testUpdateUserProfile_whenUserNotLoggedIn_throwsError() async {
        // Given
        mockAuth.currentUser = nil
        
        // When/Then
        do {
            try await sut.updateUserProfile(displayName: "Name", photoURL: nil)
            XCTFail("Should have thrown an error")
        } catch {
            // Success - erreur attendue
        }
    }
    
    func testDeleteAccount_whenUserLoggedIn_deletesAccount() async throws {
        // Given
        mockAuth.currentUser = mockUser
        var deleteWasCalled = false
        
        mockAuth.deleteAccountCallback = {
            deleteWasCalled = true
        }
        
        // When
        try await sut.deleteAccount()
        
        // Then
        XCTAssertTrue(deleteWasCalled)
    }
    
    func testDeleteAccount_whenUserNotLoggedIn_throwsError() async {
        // Given
        mockAuth.currentUser = nil
        
        // When/Then
        do {
            try await sut.deleteAccount()
            XCTFail("Should have thrown an error")
        } catch {
            // Success - erreur attendue
        }
    }
    
    func testResetPassword_whenCalled_sendsResetEmail() async throws {
        // Given
        var capturedEmail: String?
        mockAuth.resetPasswordCallback = { email in
            capturedEmail = email
        }
        
        // When
        try await sut.resetPassword(email: "reset@example.com")
        
        // Then
        XCTAssertEqual(capturedEmail, "reset@example.com")
    }
}

// MARK: - Mock Auth Provider pour l'injection

/// Protocole pour permettre l'injection de dépendances dans FirebaseAuthenticationService
protocol AuthServiceInjectable {
    func injectAuthProvider(_ provider: AuthProviderProtocol)
}

/// Mock de l'implémentation de AuthProviderProtocol pour les tests
class MockAuthProvider: AuthProviderProtocol {
    private let mockAuth = FirebaseAuthenticationServiceTests.MockAuth.shared
    
    var currentUser: UserProtocol? {
        return mockAuth.currentUser
    }
    
    func signIn(withEmail email: String, password: String) async throws -> AuthDataResultProtocol {
        if let callback = mockAuth.signInCallback {
            return try await callback(email, password)
        }
        throw NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock implementation"])
    }
    
    func createUser(withEmail email: String, password: String) async throws -> AuthDataResultProtocol {
        if let callback = mockAuth.createUserCallback {
            return try await callback(email, password)
        }
        throw NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock implementation"])
    }
    
    func signOut() throws {
        if let callback = mockAuth.signOutCallback {
            try callback()
        } else {
            throw NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No mock implementation"])
        }
    }
    
    func getCurrentUser() -> UserProtocol? {
        return mockAuth.currentUser
    }
    
    func isUserAuthenticated() -> Bool {
        return mockAuth.currentUser != nil
    }
    
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        if let user = mockAuth.currentUser {
            var request = FirebaseAuthenticationServiceTests.MockAuth.ProfileChangeRequest()
            request.displayName = displayName
            request.photoURL = photoURL
            
            if let callback = mockAuth.updateProfileCallback {
                try await callback(&request)
            }
        } else {
            throw NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])
        }
    }
}
