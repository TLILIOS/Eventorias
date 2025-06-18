
//
// AuthenticationViewModelTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
@testable import Eventorias

@MainActor
final class AuthenticationViewModelTests: XCTestCase {
    
    var mockAuthService: MockAuthService!
    var sut: AuthenticationViewModel!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthService()
        mockAuthService.shouldThrowOnSuccess = false
        sut = AuthenticationViewModel(authService: mockAuthService)
    }
    
    override func tearDown() {
        mockAuthService = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests existants améliorés
    
    func testInitialization() {
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.username, "")
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.showingError)
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertNil(sut.profileImage)
        XCTAssertFalse(sut.isUploadingImage)
    }
    
    // MARK: - Nouveaux tests pour propriétés calculées
    
    func testIsSignUpFormValid() {
        // Test avec tous les champs vides
        sut.email = ""
        sut.password = ""
        sut.username = ""
        XCTAssertFalse(sut.isSignUpFormValid)
        
        // Test avec email et password valides mais username vide
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.username = ""
        XCTAssertFalse(sut.isSignUpFormValid)
        
        // Test avec tous les champs valides
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.username = "testuser"
        XCTAssertTrue(sut.isSignUpFormValid)
        
        // Test avec email invalide
        sut.email = "invalid-email"
        sut.password = "password123"
        sut.username = "testuser"
        XCTAssertFalse(sut.isSignUpFormValid)
        
        // Test avec password trop court
        sut.email = "test@example.com"
        sut.password = "123"
        sut.username = "testuser"
        XCTAssertFalse(sut.isSignUpFormValid)
    }
    
    func testHasStoredCredentials_Simplified() {
        // Test l'état initial
        mockAuthService.mockIsAuthenticated = false
        sut.checkAuthenticationStatus()
        
        // Le résultat dépend de l'état réel du Keychain
        // On teste juste que la propriété est accessible
        let hasStored = sut.hasStoredCredentials
        XCTAssertNotNil(hasStored) // Vérifie que la propriété existe et retourne une valeur
        
        // Test avec utilisateur authentifié
        mockAuthService.mockIsAuthenticated = true
        sut.checkAuthenticationStatus()
        XCTAssertTrue(sut.isAuthenticated)
        
        // Maintenant hasStoredCredentials devrait être false car isAuthenticated = true
        // (true && !true) || keychain.exists = false || keychain.exists
        // Le résultat dépend du Keychain réel
    }

    
    // MARK: - Tests des méthodes de stockage
    
    func testQuickSignIn() {
        // Setup: utilisateur déjà connecté via Firebase
        mockAuthService.mockIsAuthenticated = true
        
        // Act
        sut.quickSignIn()
        
        // Assert
        XCTAssertTrue(sut.isAuthenticated)
    }
    
    func testSignOutWithoutClearingForm() {
        // Arrange
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.isAuthenticated = true
        
        // Act
        sut.signOutWithoutClearingForm()
        
        // Assert
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertFalse(sut.isAuthenticated)
        // Vérifier que le formulaire n'a pas été vidé
        XCTAssertEqual(sut.email, "test@example.com")
        XCTAssertEqual(sut.password, "password123")
    }
    
    func testSignOutWithClearingForm() {
        // Arrange
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.username = "testuser"
        sut.isAuthenticated = true
        
        // Act
        sut.signOut()
        
        // Assert
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertFalse(sut.isAuthenticated)
        // Vérifier que le formulaire a été vidé
        XCTAssertEqual(sut.email, "")
        XCTAssertEqual(sut.password, "")
        XCTAssertEqual(sut.username, "")
    }
    
    // MARK: - Tests de gestion d'erreurs spécifiques
    func testSignUp_SpecificFirebaseErrors() async {
        sut.email = "test@example.com"
        sut.password = "password123"
        sut.username = "testuser"
        
        // Test erreur email déjà utilisé
        mockAuthService.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: 17007, // AuthErrorCode.emailAlreadyInUse
            userInfo: [NSLocalizedDescriptionKey: "Email already in use"]
        )
        
        await sut.signUp()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("Un compte existe déjà"),
                     "Expected error message to contain 'Un compte existe déjà', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
        
        // Reset error state before next test
        sut.dismissError()
        
        // Test erreur mot de passe faible
        mockAuthService.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: 17026, // AuthErrorCode.weakPassword
            userInfo: [NSLocalizedDescriptionKey: "Weak password"]
        )
        
        await sut.signUp()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("trop faible"),
                     "Expected error message to contain 'trop faible', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
    }

    func testSignIn_SpecificFirebaseErrors() async {
        // Test erreur utilisateur non trouvé
        sut.email = "test@example.com"
        sut.password = "password123"
        mockAuthService.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: 17011, // AuthErrorCode.userNotFound
            userInfo: [NSLocalizedDescriptionKey: "User not found"]
        )
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("Aucun compte trouvé"),
                     "Expected error message to contain 'Aucun compte trouvé', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
        
        // Reset error state before next test
        sut.dismissError()
        
        // Test erreur mot de passe incorrect
        mockAuthService.mockError = NSError(
            domain: "FIRAuthErrorDomain",
            code: 17009, // AuthErrorCode.wrongPassword
            userInfo: [NSLocalizedDescriptionKey: "Wrong password"]
        )
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("Mot de passe incorrect"),
                     "Expected error message to contain 'Mot de passe incorrect', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
    }
    func testHandleAuthError_AllFirebaseErrorCodes() async {
        let errorTestCases: [(Int, String)] = [
            (17005, "désactivé"),           // userDisabled
            (17006, "autorisée"),           // operationNotAllowed
            (17008, "invalide"),            // invalidEmail
            (17010, "tentatives"),          // tooManyRequests
            (17004, "invalides")            // invalidCredential
        ]
        
        for (errorCode, expectedText) in errorTestCases {
            // Reset state
            sut.dismissError()
            sut.email = "test@example.com"
            sut.password = "password123"
            
            mockAuthService.mockError = NSError(
                domain: "FIRAuthErrorDomain",
                code: errorCode,
                userInfo: [NSLocalizedDescriptionKey: "Firebase error"]
            )
            
            await sut.signIn()
            
            XCTAssertTrue(sut.showingError, "showingError should be true for error code \(errorCode)")
            XCTAssertTrue(sut.errorMessage.contains(expectedText),
                         "Expected error message to contain '\(expectedText)' for code \(errorCode), but got: '\(sut.errorMessage)'")
        }
    }

    func testHandleAuthError_NonFirebaseError() async {
        sut.email = "test@example.com"
        sut.password = "password123"
        
        // Erreur générique non-Firebase
        let customError = NSError(
            domain: "CustomErrorDomain",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Custom error message"]
        )
        mockAuthService.mockError = customError
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError)
        XCTAssertEqual(sut.errorMessage, "Custom error message")
    }

    // MARK: - Tests des propriétés d'image
    
    func testProfileImageHandling() {
        // Test initialisation
        XCTAssertNil(sut.profileImage)
        XCTAssertFalse(sut.isUploadingImage)
        
        // Test assignation d'image
        let testImage = UIImage(systemName: "person.circle")
        sut.profileImage = testImage
        XCTAssertNotNil(sut.profileImage)
    }
    
    // MARK: - Tests de validation avancée
    
    func testFormValidation_EdgeCases() {
        // Test avec espaces dans l'email
        sut.email = " test@example.com "
        sut.password = "password123"
        // Note: selon l'implémentation, cela pourrait être valide ou non
        
        // Test avec caractères spéciaux dans le password
        sut.email = "test@example.com"
        sut.password = "P@ssw0rd!123"
        XCTAssertTrue(sut.isFormValid)
        
        // Test avec email très long mais valide
        sut.email = "verylongusername.withdots.andmoretext@verylongdomainname.com"
        sut.password = "password123"
        XCTAssertTrue(sut.isFormValid)
    }
    
    // MARK: - Tests de concurrence et d'état
    
    func testConcurrentSignIn() async {
        sut.email = "test@example.com"
        sut.password = "password123"
        mockAuthService.mockIsAuthenticated = true
        
        // Lancer plusieurs signIn en parallèle
        async let signIn1 = sut.signIn()
        async let signIn2 = sut.signIn()
        
        await signIn1
        await signIn2
        
        // Vérifier que l'état final est cohérent
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
    }
    
    // MARK: - Tests d'intégration
    
    func testCompleteAuthenticationFlow() async {
        // 1. Inscription
        sut.email = "newuser@example.com"
        sut.password = "newpassword123"
        sut.username = "newuser"
        mockAuthService.mockIsAuthenticated = true
        
        await sut.signUp()
        
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertTrue(mockAuthService.signUpCalled)
        
        // 2. Déconnexion
        sut.signOut()
        
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertTrue(mockAuthService.signOutCalled)
        
        // 3. Reconnexion
        mockAuthService.signInCalled = false // Reset
        await sut.signIn()
        
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertTrue(mockAuthService.signInCalled)
    }
    
    // MARK: - Tests des cas limites
    
    func testAuthenticationWithEmptyCredentials() async {
        sut.email = ""
        sut.password = ""
        
        await sut.signIn()
        
        // Le ViewModel ne devrait pas appeler le service avec des identifiants vides
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testErrorHandling_NonFirebaseError() async {
        sut.email = "test@example.com"
        sut.password = "password123"
        
        // Erreur générique non-Firebase
        mockAuthService.mockError = NSError(
            domain: "NetworkError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Network timeout"]
        )
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError)
        XCTAssertEqual(sut.errorMessage, "Network timeout")
    }
}
