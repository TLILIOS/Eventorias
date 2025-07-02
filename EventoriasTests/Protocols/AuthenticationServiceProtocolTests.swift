//
//  AuthenticationServiceProtocolTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
@testable import Eventorias
@MainActor
final class AuthenticationServiceProtocolTests: XCTestCase {

    // MARK: - Tests de conformité au protocole
    
    func testFirebaseAuthServiceProtocolConformance() {
        // Arrange
        let authService = FirebaseAuthenticationService()
        
        // Act & Assert
        XCTAssertTrue(authService is AuthenticationServiceProtocol, "FirebaseAuthenticationService doit se conformer à AuthenticationServiceProtocol")
    }
    
    func testMockAuthServiceProtocolConformance() {
        // Arrange
        let mockAuthService = MockAuthenticationService()
        
        // Act & Assert
        XCTAssertTrue(mockAuthService is AuthenticationServiceProtocol, "MockAuthenticationService doit se conformer à AuthenticationServiceProtocol")
    }
    
    // MARK: - Tests de comportement polymorphique
    
    func testAuthProtocolBehaviorWithDifferentImplementations() {
        // Arrange
        let mockAuthService = MockAuthenticationService()
        
        // Nous utilisons seulement le mock pour les tests unitaires car nous ne voulons pas dépendre de Firebase
        let authServices: [AuthenticationServiceProtocol] = [mockAuthService]
        
        // Test comportement polymorphique - vérification email
        for (index, service) in authServices.enumerated() {
            // Act & Assert
            XCTAssertTrue(service.isValidEmail("test@example.com"), "L'implémentation \(index) devrait valider un email correct")
            XCTAssertFalse(service.isValidEmail("invalid"), "L'implémentation \(index) ne devrait pas valider un email incorrect")
        }
        
        // Test comportement polymorphique - vérification mot de passe
        for (index, service) in authServices.enumerated() {
            // Act & Assert
            XCTAssertTrue(service.isValidPassword("password123"), "L'implémentation \(index) devrait valider un mot de passe correct")
            XCTAssertFalse(service.isValidPassword("123"), "L'implémentation \(index) ne devrait pas valider un mot de passe trop court")
        }
    }
    
    // MARK: - Tests des méthodes asynchrones
    
    func testAsyncMethodsWithMockImplementation() async {
        // Arrange
        let mockAuthService = MockAuthenticationService()
        mockAuthService.shouldThrowError = false
        
        // Test de connexion
        do {
            let result = try await mockAuthService.signIn(email: "test@example.com", password: "password123")
            XCTAssertEqual(result.user.email, "test@example.com", "L'email de l'utilisateur connecté ne correspond pas")
        } catch {
            XCTFail("La méthode signIn du protocole a échoué: \(error.localizedDescription)")
        }
        
        // Test d'inscription
        do {
            let result = try await mockAuthService.signUp(email: "new@example.com", password: "password123")
            XCTAssertEqual(result.user.email, "new@example.com", "L'email de l'utilisateur inscrit ne correspond pas")
        } catch {
            XCTFail("La méthode signUp du protocole a échoué: \(error.localizedDescription)")
        }
        
        // Test de mise à jour de profil
        do {
            try await mockAuthService.updateUserProfile(displayName: "Nouveau nom", photoURL: nil)
            XCTAssertEqual(mockAuthService.currentUserDisplayNameMock, "Nouveau nom", "Le nom d'affichage n'a pas été mis à jour")
        } catch {
            XCTFail("La méthode updateUserProfile du protocole a échoué: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests des erreurs possibles
    
    func testErrorHandlingInProtocolMethods() async {
        // Arrange
        let mockAuthService = MockAuthenticationService()
        mockAuthService.shouldThrowError = true
        mockAuthService.mockError = NSError(domain: "TestAuthError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée pour test"])
        
        // Test de connexion avec erreur
        do {
            _ = try await mockAuthService.signIn(email: "test@example.com", password: "password123")
            XCTFail("La méthode signIn aurait dû échouer")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "TestAuthError", "Le domaine d'erreur ne correspond pas")
            XCTAssertEqual(error.code, 999, "Le code d'erreur ne correspond pas")
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
        
        // Test de déconnexion avec erreur
        do {
            try mockAuthService.signOut()
            XCTFail("La méthode signOut aurait dû échouer")
        } catch let error as NSError {
            XCTAssertEqual(error.domain, "TestAuthError", "Le domaine d'erreur ne correspond pas")
            XCTAssertEqual(error.code, 999, "Le code d'erreur ne correspond pas")
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
}
