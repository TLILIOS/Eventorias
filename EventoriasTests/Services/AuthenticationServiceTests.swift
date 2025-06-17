
//
// AuthenticationServiceTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
@testable import Eventorias
import FirebaseAuth

class AuthenticationServiceTests: XCTestCase {
    
    var authService: AuthenticationService!
    var mockAuth: MockAuthService!
    
    override func setUp() {
        super.setUp()
        mockAuth = MockAuthService()
        mockAuth.configureForServiceTests() // Configuration appropriée pour les tests de service
        authService = mockAuth
    }
    
    override func tearDown() {
        // Reset explicite pour garantir l'isolation des tests
        mockAuth?.reset()
        mockAuth = nil
        authService = nil
        super.tearDown()
    }
    
    // MARK: - Tests de validation de base avec reset
    
    func testEmailValidation_BasicCases() {
        // Reset avant test pour s'assurer de l'état propre
        mockAuth.reset()
        
        // Valid emails - y compris domaines d'une seule lettre
        XCTAssertTrue(authService.isValidEmail("test@example.com"))
        XCTAssertTrue(authService.isValidEmail("user.name+tag@domain.co.uk"))
        XCTAssertTrue(authService.isValidEmail("a@b.c")) // Maintenant supporté
        XCTAssertTrue(authService.isValidEmail("user@x.co")) // Domaine d'une lettre
        XCTAssertTrue(authService.isValidEmail("test@a.museum")) // TLD long avec domaine court
        
        // Vérifier que les appels sont trackés
        XCTAssertTrue(mockAuth.isValidEmailCalled)
        
        // Invalid emails
        XCTAssertFalse(authService.isValidEmail(""))
        XCTAssertFalse(authService.isValidEmail("test"))
        XCTAssertFalse(authService.isValidEmail("test@"))
        XCTAssertFalse(authService.isValidEmail("@example.com"))
        XCTAssertFalse(authService.isValidEmail("test@example"))
        XCTAssertFalse(authService.isValidEmail("test@.com"))
        XCTAssertFalse(authService.isValidEmail("test@example."))
    }
    
    func testEmailValidation_SingleCharacterDomains() {
        mockAuth.reset()
        
        // Emails valides avec domaines d'une lettre
        let validSingleCharDomains = [
            "user@a.com",
            "test@b.org",
            "email@x.co",
            "name@z.info"
        ]
        
        for email in validSingleCharDomains {
            XCTAssertTrue(authService.isValidEmail(email), "Should be valid: \(email)")
        }
        
        // Emails toujours invalides
        let invalidEmails = [
            "user@.com",     // Pas de domaine
            "user@a.",       // Pas de TLD
            "user@a",        // Pas de TLD du tout
            "@a.com"         // Pas de partie locale
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(authService.isValidEmail(email), "Should be invalid: \(email)")
        }
    }

    
    func testPasswordValidation_BasicCases() {
        // Reset avant test
        mockAuth.reset()
        
        // Valid passwords (at least 6 characters)
        XCTAssertTrue(authService.isValidPassword("123456"))
        XCTAssertTrue(authService.isValidPassword("password123"))
        XCTAssertTrue(authService.isValidPassword("Secure!Password"))
        
        // Vérifier que les appels sont trackés
        XCTAssertTrue(mockAuth.isValidPasswordCalled)
        
        // Invalid passwords (less than 6 characters)
        XCTAssertFalse(authService.isValidPassword(""))
        XCTAssertFalse(authService.isValidPassword("123"))
        XCTAssertFalse(authService.isValidPassword("pass"))
    }
    
    // MARK: - Tests d'authentification avec reset
    
    func testSignIn_Success_WithReset() async {
        // Configuration pour succès
        mockAuth.configureForViewModelTests() // Mode succès
        mockAuth.configureAuthState(isAuthenticated: true)
        
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        do {
            let result = try await authService.signIn(email: testEmail, password: testPassword)
            XCTAssertNotNil(result)
            XCTAssertTrue(mockAuth.signInCalled)
            XCTAssertEqual(mockAuth.lastEmail, testEmail)
            XCTAssertEqual(mockAuth.lastPassword, testPassword)
            // Vérifier qu'une seule méthode a été appelée
            XCTAssertEqual(mockAuth.totalMethodCalls, 1)
        } catch {
            XCTFail("Should not throw error in success mode: \(error)")
        }
    }
    
    func testSignIn_Failure_WithReset() async {
        // Configuration pour échec
        let expectedError = NSError(domain: "AuthError", code: 1,
                                  userInfo: [NSLocalizedDescriptionKey: "Authentication failed"])
        mockAuth.configureError(expectedError)
        
        do {
            _ = try await authService.signIn(email: "test@example.com", password: "password123")
            XCTFail("Sign in should throw an error")
        } catch {
            XCTAssertTrue(mockAuth.signInCalled)
            XCTAssertEqual((error as NSError).domain, "AuthError")
            XCTAssertEqual((error as NSError).code, 1)
            // Vérifier l'isolation - pas d'autres méthodes appelées
            XCTAssertFalse(mockAuth.signUpCalled)
            XCTAssertFalse(mockAuth.signOutCalled)
        }
    }
    
    func testSignUp_Success_WithReset() async {
        // Configuration pour succès
        mockAuth.configureForViewModelTests() // Mode succès
        mockAuth.configureAuthState(isAuthenticated: true)
        
        let testEmail = "newuser@example.com"
        let testPassword = "newpassword123"
        
        do {
            let result = try await authService.signUp(email: testEmail, password: testPassword)
            XCTAssertNotNil(result)
            XCTAssertTrue(mockAuth.signUpCalled)
            XCTAssertEqual(mockAuth.lastEmail, testEmail)
            XCTAssertEqual(mockAuth.lastPassword, testPassword)
            XCTAssertTrue(mockAuth.mockIsAuthenticated)
        } catch {
            XCTFail("Should not throw error in success mode: \(error)")
        }
    }
    
    func testSignUp_Failure_WithReset() async {
        // Configuration pour échec
        let expectedError = NSError(domain: "AuthError", code: 2,
                                  userInfo: [NSLocalizedDescriptionKey: "Registration failed"])
        mockAuth.configureError(expectedError)
        
        do {
            _ = try await authService.signUp(email: "test@example.com", password: "password123")
            XCTFail("Sign up should throw an error")
        } catch {
            XCTAssertTrue(mockAuth.signUpCalled)
            XCTAssertEqual((error as NSError).domain, "AuthError")
            XCTAssertEqual((error as NSError).code, 2)
            // Vérifier l'isolation
            XCTAssertFalse(mockAuth.signInCalled)
        }
    }
    
    // MARK: - Tests de déconnexion avec reset
    
    func testSignOut_Success_WithReset() throws {
        // Reset et configuration
        mockAuth.reset()
        mockAuth.configureAuthState(isAuthenticated: true)
        
        try authService.signOut()
        
        XCTAssertTrue(mockAuth.signOutCalled)
        XCTAssertFalse(mockAuth.mockIsAuthenticated) // Vérifier que l'état a changé
        // Vérifier qu'aucune autre méthode n'a été appelée
        XCTAssertFalse(mockAuth.signInCalled)
        XCTAssertFalse(mockAuth.signUpCalled)
    }
    
    func testSignOut_Failure_WithReset() {
        // Configuration d'erreur spécifique
        let expectedError = NSError(domain: "AuthError", code: 3,
                                  userInfo: [NSLocalizedDescriptionKey: "Sign out failed"])
        mockAuth.configureError(expectedError)
        
        do {
            try authService.signOut()
            XCTFail("Sign out should throw an error")
        } catch {
            XCTAssertTrue(mockAuth.signOutCalled)
            XCTAssertEqual((error as NSError).domain, "AuthError")
            XCTAssertEqual((error as NSError).code, 3)
        }
    }
    
    // MARK: - Tests d'état d'authentification avec reset
    
    func testIsUserAuthenticated_WithReset() {
        // Test état initial après reset
        mockAuth.reset()
        XCTAssertFalse(authService.isUserAuthenticated())
        XCTAssertTrue(mockAuth.isUserAuthenticatedCalled)
        
        // Reset et changement d'état
        mockAuth.reset()
        mockAuth.configureAuthState(isAuthenticated: true)
        XCTAssertTrue(authService.isUserAuthenticated())
        XCTAssertTrue(mockAuth.isUserAuthenticatedCalled)
        
        // Vérifier que le compteur d'appels est correct après reset
        XCTAssertEqual(mockAuth.totalMethodCalls, 1)
    }
    
    func testGetCurrentUser_WithReset() {
        // Test avec reset initial
        mockAuth.reset()
        
        let currentUser = authService.getCurrentUser()
        XCTAssertTrue(mockAuth.getCurrentUserCalled)
        XCTAssertNil(currentUser) // MockAuthService retourne toujours nil
        
        // Vérifier isolation
        XCTAssertFalse(mockAuth.signInCalled)
        XCTAssertFalse(mockAuth.signUpCalled)
        XCTAssertEqual(mockAuth.totalMethodCalls, 1)
    }
    
    // MARK: - Tests de séquences complètes avec reset
    
    func testCompleteAuthSequence_WithResets() async {
        // 1. Inscription avec reset
        mockAuth.configureForViewModelTests()
        
        do {
            _ = try await authService.signUp(email: "user@test.com", password: "password123")
            XCTAssertTrue(mockAuth.signUpCalled)
            XCTAssertTrue(mockAuth.mockIsAuthenticated)
        } catch {
            XCTFail("Signup should succeed: \(error)")
        }
        
        // 2. Vérification d'état (sans reset pour garder l'état)
        XCTAssertTrue(authService.isUserAuthenticated())
        XCTAssertTrue(mockAuth.isUserAuthenticatedCalled)
        
        // 3. Déconnexion
        mockAuth.mockError = nil // S'assurer qu'il n'y a pas d'erreur
        try? authService.signOut()
        XCTAssertTrue(mockAuth.signOutCalled)
        XCTAssertFalse(mockAuth.mockIsAuthenticated)
        
        // 4. Reconnexion
        do {
            _ = try await authService.signIn(email: "user@test.com", password: "password123")
            XCTAssertTrue(mockAuth.signInCalled)
        } catch {
            XCTFail("Sign in should succeed: \(error)")
        }
        
        // Vérifier que toutes les opérations ont été appelées
        XCTAssertTrue(mockAuth.signUpCalled)
        XCTAssertTrue(mockAuth.isUserAuthenticatedCalled)
        XCTAssertTrue(mockAuth.signOutCalled)
        XCTAssertTrue(mockAuth.signInCalled)
    }
    
    // MARK: - Tests de validation étendue avec reset
    
    func testEmailValidation_ExtensiveTests_WithReset() {
        mockAuth.reset()
        
        // Emails valides
        let validEmails = [
            "test@example.com",
            "user.name+tag@domain.co.uk",
            "firstname.lastname@company.org",
            "a@b.co",
            "user123@test-domain.com",
            "user+label@example.museum"
        ]
        
        for email in validEmails {
            XCTAssertTrue(authService.isValidEmail(email), "Should be valid: \(email)")
        }
        
        // Reset et test des emails invalides
        mockAuth.reset()
        
        let invalidEmails = [
            "",
            "test",
            "test@",
            "@example.com",
            "test@example",
            "test.example.com",
            "test@@example.com"
        ]
        
        for email in invalidEmails {
            XCTAssertFalse(authService.isValidEmail(email), "Should be invalid: \(email)")
        }
        
        // Vérifier que les appels sont toujours trackés après reset
        XCTAssertTrue(mockAuth.isValidEmailCalled)
    }
    
    // MARK: - Tests de performance avec reset
    
    func testValidation_Performance_WithReset() {
        mockAuth.reset()
        
        let longEmail = String(repeating: "a", count: 1000) + "@example.com"
        let longPassword = String(repeating: "p", count: 1000)
        
        measure {
            _ = authService.isValidEmail(longEmail)
            _ = authService.isValidPassword(longPassword)
        }
        
        // Vérifier que les appels ont été trackés
        XCTAssertTrue(mockAuth.isValidEmailCalled)
        XCTAssertTrue(mockAuth.isValidPasswordCalled)
    }
    
    // MARK: - Tests d'isolation entre tests
    
    func testIsolation_BetweenTests() {
        // Ce test vérifie que les états ne se mélangent pas entre les tests
        // Il devrait être executé après d'autres tests mais avoir un état propre
        
        // Vérifier que l'état est clean après setUp/tearDown
        XCTAssertTrue(mockAuth.hasNoMethodsCalled, "Mock should be clean after reset")
        XCTAssertFalse(mockAuth.mockIsAuthenticated)
        XCTAssertNil(mockAuth.mockError)
        XCTAssertNil(mockAuth.lastEmail)
        XCTAssertNil(mockAuth.lastPassword)
        
        // Effectuer une opération
        mockAuth.configureAuthState(isAuthenticated: true)
        let isAuth = authService.isUserAuthenticated()
        
        XCTAssertTrue(isAuth)
        XCTAssertTrue(mockAuth.isUserAuthenticatedCalled)
        XCTAssertEqual(mockAuth.totalMethodCalls, 1)
    }
    
    // MARK: - Tests edge cases avec reset
    
    func testEdgeCases_WithReset() {
        mockAuth.reset()
        
        // Test avec caractères Unicode (maintenant supportés)
        XCTAssertTrue(authService.isValidEmail("tëst@ëxamplë.com"))
        XCTAssertTrue(authService.isValidPassword("pässwörd123"))
        
        // Test avec caractères ASCII traditionnels
        XCTAssertTrue(authService.isValidEmail("test@example.com"))
        
        // Test limites exactes
        XCTAssertFalse(authService.isValidPassword("12345")) // 5 chars
        XCTAssertTrue(authService.isValidPassword("123456"))  // 6 chars
        
        // Vérifier tracking
        XCTAssertTrue(mockAuth.isValidEmailCalled)
        XCTAssertTrue(mockAuth.isValidPasswordCalled)
    }
}
