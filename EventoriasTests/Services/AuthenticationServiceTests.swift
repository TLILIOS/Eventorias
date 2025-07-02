//
//  AuthenticationServiceTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
@testable import Eventorias
@MainActor
final class AuthenticationServiceTests: XCTestCase {
    
    var mockAuthService: MockAuthenticationService!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
    }
    
    override func tearDown() {
        mockAuthService = nil
        super.tearDown()
    }
    
    // MARK: - Tests de connexion utilisateur
    
    func testSignInSuccess() async {
        // Arrange
        mockAuthService.shouldThrowError = false
        
        // Act
        do {
            let result = try await mockAuthService.signIn(email: "test@example.com", password: "password123")
            
            // Assert
            XCTAssertTrue(mockAuthService.signInCalled, "La méthode signIn n'a pas été appelée")
            XCTAssertEqual(result.user.email, "test@example.com", "L'email de l'utilisateur ne correspond pas")
            XCTAssertNotNil(mockAuthService.currentUser, "L'utilisateur courant est nil après connexion")
        } catch {
            XCTFail("La connexion a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testSignInFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await mockAuthService.signIn(email: "test@example.com", password: "password123")
            XCTFail("La connexion a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockAuthService.signInCalled, "La méthode signIn n'a pas été appelée")
            XCTAssertNil(mockAuthService.currentUser, "L'utilisateur courant n'est pas nil après échec de connexion")
        }
    }
    
    // MARK: - Tests d'inscription utilisateur
    
    func testSignUpSuccess() async {
        // Arrange
        mockAuthService.shouldThrowError = false
        
        // Act
        do {
            let result = try await mockAuthService.signUp(email: "new@example.com", password: "newpassword123")
            
            // Assert
            XCTAssertTrue(mockAuthService.signUpCalled, "La méthode signUp n'a pas été appelée")
            XCTAssertEqual(result.user.email, "new@example.com", "L'email de l'utilisateur ne correspond pas")
            XCTAssertNotNil(mockAuthService.currentUser, "L'utilisateur courant est nil après inscription")
        } catch {
            XCTFail("L'inscription a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testSignUpFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await mockAuthService.signUp(email: "new@example.com", password: "newpassword123")
            XCTFail("L'inscription a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockAuthService.signUpCalled, "La méthode signUp n'a pas été appelée")
        }
    }
    
    // MARK: - Tests de déconnexion
    
    func testSignOutSuccess() {
        // Arrange
        mockAuthService.shouldThrowError = false
        mockAuthService.currentUserMock = MockUser(uid: "test-uid", email: "test@example.com")
        
        // Act
        do {
            try mockAuthService.signOut()
            
            // Assert
            XCTAssertTrue(mockAuthService.signOutCalled, "La méthode signOut n'a pas été appelée")
            XCTAssertNil(mockAuthService.currentUser, "L'utilisateur courant n'est pas nil après déconnexion")
        } catch {
            XCTFail("La déconnexion a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testSignOutFailure() {
        // Arrange
        mockAuthService.shouldThrowError = true
        
        // Act & Assert
        do {
            try mockAuthService.signOut()
            XCTFail("La déconnexion a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockAuthService.signOutCalled, "La méthode signOut n'a pas été appelée")
        }
    }
    
    // MARK: - Tests de vérification d'authentification
    
    func testIsUserAuthenticated() {
        // Arrange
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // Act
        let isAuthenticated = mockAuthService.isUserAuthenticated()
        
        // Assert
        XCTAssertTrue(mockAuthService.isUserAuthenticatedCalled, "La méthode isUserAuthenticated n'a pas été appelée")
        XCTAssertTrue(isAuthenticated, "L'utilisateur devrait être authentifié")
    }
    
    func testIsUserNotAuthenticated() {
        // Arrange
        mockAuthService.isUserAuthenticatedReturnValue = false
        
        // Act
        let isAuthenticated = mockAuthService.isUserAuthenticated()
        
        // Assert
        XCTAssertTrue(mockAuthService.isUserAuthenticatedCalled, "La méthode isUserAuthenticated n'a pas été appelée")
        XCTAssertFalse(isAuthenticated, "L'utilisateur ne devrait pas être authentifié")
    }
    
    // MARK: - Tests de validation
    
    func testIsValidEmail() {
        // Arrange
        let validEmail = "test@example.com"
        let invalidEmail = "test@"
        
        // Act & Assert
        XCTAssertTrue(mockAuthService.isValidEmail(validEmail), "L'email valide n'est pas reconnu")
        XCTAssertFalse(mockAuthService.isValidEmail(invalidEmail), "L'email invalide n'est pas détecté")
        XCTAssertTrue(mockAuthService.isValidEmailCalled, "La méthode isValidEmail n'a pas été appelée")
    }
    
    func testIsValidPassword() {
        // Arrange
        let validPassword = "password123"
        let invalidPassword = "pass"
        
        // Act & Assert
        XCTAssertTrue(mockAuthService.isValidPassword(validPassword), "Le mot de passe valide n'est pas reconnu")
        XCTAssertFalse(mockAuthService.isValidPassword(invalidPassword), "Le mot de passe invalide n'est pas détecté")
        XCTAssertTrue(mockAuthService.isValidPasswordCalled, "La méthode isValidPassword n'a pas été appelée")
    }
    
    // MARK: - Tests de mise à jour de profil
    
    func testUpdateUserProfileSuccess() async {
        // Arrange
        mockAuthService.shouldThrowError = false
        mockAuthService.currentUserMock = MockUser(uid: "test-uid", email: "test@example.com")
        let newDisplayName = "Nouveau Nom"
        
        // Act
        do {
            try await mockAuthService.updateUserProfile(displayName: newDisplayName, photoURL: nil)
            
            // Assert
            XCTAssertTrue(mockAuthService.updateUserProfileCalled, "La méthode updateUserProfile n'a pas été appelée")
            XCTAssertEqual(mockAuthService.currentUserDisplayNameMock, newDisplayName, "Le nom d'affichage n'a pas été mis à jour")
        } catch {
            XCTFail("La mise à jour du profil a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testUpdateUserProfileFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        
        // Act & Assert
        do {
            try await mockAuthService.updateUserProfile(displayName: "Test", photoURL: nil)
            XCTFail("La mise à jour du profil a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockAuthService.updateUserProfileCalled, "La méthode updateUserProfile n'a pas été appelée")
        }
    }
    
    // MARK: - Tests de suppression de compte
    
    func testDeleteAccountSuccess() async {
        // Arrange
        mockAuthService.shouldThrowError = false
        mockAuthService.currentUserMock = MockUser(uid: "test-uid", email: "test@example.com")
        
        // Act
        do {
            try await mockAuthService.deleteAccount()
            
            // Assert
            XCTAssertTrue(mockAuthService.deleteAccountCalled, "La méthode deleteAccount n'a pas été appelée")
            XCTAssertNil(mockAuthService.currentUser, "L'utilisateur courant n'est pas nil après suppression du compte")
        } catch {
            XCTFail("La suppression du compte a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testDeleteAccountFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        
        // Act & Assert
        do {
            try await mockAuthService.deleteAccount()
            XCTFail("La suppression du compte a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockAuthService.deleteAccountCalled, "La méthode deleteAccount n'a pas été appelée")
        }
    }
    
    // MARK: - Tests de réinitialisation de mot de passe
    
    func testResetPasswordSuccess() async {
        // Arrange
        mockAuthService.shouldThrowError = false
        
        // Act
        do {
            try await mockAuthService.resetPassword(email: "test@example.com")
            
            // Assert
            XCTAssertTrue(mockAuthService.resetPasswordCalled, "La méthode resetPassword n'a pas été appelée")
        } catch {
            XCTFail("La réinitialisation du mot de passe a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testResetPasswordFailure() async {
        // Arrange
        mockAuthService.shouldThrowError = true
        
        // Act & Assert
        do {
            try await mockAuthService.resetPassword(email: "test@example.com")
            XCTFail("La réinitialisation du mot de passe a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockAuthService.resetPasswordCalled, "La méthode resetPassword n'a pas été appelée")
        }
    }
}
