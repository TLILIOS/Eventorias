
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
    
    var mockAuthService: MockAuthenticationService!
    var mockKeychainService: MockKeychainService!
    var sut: AuthenticationViewModel!
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        mockKeychainService = MockKeychainService()
        
        // Configuration des mocks pour les tests
        mockAuthService.configureForSuccess()
        mockKeychainService.configureForSuccess()
        
        // Injection des dépendances via le constructeur
        sut = AuthenticationViewModel(authService: mockAuthService, keychainService: mockKeychainService)
    }
    
    override func tearDown() {
        mockAuthService = nil
        mockKeychainService = nil
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
    
    func testHasStoredCredentials() {
        // Test l'état initial sans authentification et sans identifiants stockés
        mockAuthService.configureForError(error: NSError(domain: "Test", code: 100, userInfo: nil))
        mockKeychainService.shouldReturnNilOnRetrieve = true
        sut.checkAuthenticationStatus()
        
        // Vérifier que hasStoredCredentials renvoie false si pas d'authentification et pas d'identifiants dans le keychain
        XCTAssertFalse(sut.hasStoredCredentials)
        
        // Test avec authentification
        mockAuthService.configureForSuccess()
        sut.checkAuthenticationStatus()
        XCTAssertTrue(sut.isAuthenticated)
        
        // Maintenant hasStoredCredentials devrait être false car isAuthenticated = true
        // L'expression (isUserLoggedIn && !isAuthenticated) est fausse
        XCTAssertFalse(sut.hasStoredCredentials)
        
        // Test avec identifiants dans le keychain mais sans authentification
        mockAuthService.returnAuthenticationStatus = false
        sut.isAuthenticated = false
        mockKeychainService.shouldReturnNilOnRetrieve = false
        mockKeychainService.preloadStorage(with: [
            "userEmail": "stored@example.com"
        ])
        
        // Vérifier que hasStoredCredentials renvoie true si des identifiants sont stockés
        XCTAssertTrue(sut.hasStoredCredentials)
        XCTAssertTrue(mockKeychainService.existsCalled)
    }
    
    // MARK: - Tests des méthodes de stockage
    
    func testStoreCredentialsExplicit() async {
        // Configuration initiale
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        // Exécution de la méthode signIn qui stocke les identifiants après une connexion réussie
        sut.email = testEmail
        sut.password = testPassword
        mockAuthService.configureForSuccess()
        
        await sut.signIn()
        
        // Vérifications
        XCTAssertTrue(mockKeychainService.deleteCalled, "La méthode delete devrait être appelée pour supprimer les anciennes entrées")
        XCTAssertTrue(mockKeychainService.saveCalled, "La méthode save devrait être appelée pour sauvegarder les identifiants")
        
        // Vérifier que les bonnes valeurs sont passées aux méthodes du KeychainService
        XCTAssertEqual(mockKeychainService.lastSavedData, testEmail, "Email devrait être sauvegardé")
        XCTAssertEqual(mockKeychainService.lastSavedAccount, "userEmail", "La clé userEmail devrait être utilisée")
        
        // Vérifier que l'email et le mot de passe sont sauvegardés
        XCTAssertEqual(mockKeychainService.saveCalledCount, 2, "Save devrait être appelé deux fois, une fois pour l'email et une fois pour le mot de passe")
    }

    func testLoadStoredCredentials() {
        // Préparation du mock pour simuler des identifiants stockés
        let storedEmail = "stored@example.com"
        let storedPassword = "stored_password"
        mockKeychainService.preloadStorage(with: [
            "userEmail": storedEmail,
            "userPassword": storedPassword
        ])
        
        // Appel de la méthode à tester
        sut.loadStoredCredentials()
        
        // Vérifications
        XCTAssertTrue(mockKeychainService.existsCalled, "La méthode exists devrait être appelée")
        XCTAssertTrue(mockKeychainService.retrieveCalled, "La méthode retrieve devrait être appelée")
        XCTAssertEqual(sut.email, storedEmail, "L'email stocké devrait être chargé")
        XCTAssertEqual(sut.password, storedPassword, "Le mot de passe stocké devrait être chargé")
    }
    
    func testQuickSignIn() {
        // Setup: utilisateur déjà connecté via Firebase
        mockAuthService.configureForSuccess()
        
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
        mockAuthService.configureForError(error: NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.emailAlreadyInUse.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Email already in use"]
        ))
        
        await sut.signUp()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("Un compte existe déjà"),
                     "Expected error message to contain 'Un compte existe déjà', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
        
        // Reset error state before next test
        sut.dismissError()
        
        // Test erreur mot de passe faible
        mockAuthService.configureForError(error: NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.weakPassword.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Weak password"]
        ))
        
        await sut.signUp()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("trop faible"),
                     "Expected error message to contain 'trop faible', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
    }

    func testSignIn_SpecificFirebaseErrors() async {
        // Définir l'erreur manuellement dans le ViewModel en accédant directement aux propriétés publiées
        sut.errorMessage = "Test d'erreur manuel"
        sut.showingError = true
        
        // Test erreur utilisateur non trouvé
        sut.email = "test@example.com"
        sut.password = "password123"
        mockAuthService.configureForError(error: NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.userNotFound.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Utilisateur non trouvé"]
        ))
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError, "showingError should be true")
        XCTAssertTrue(sut.errorMessage.contains("Aucun compte trouvé"),
                     "Expected error message to contain 'Aucun compte trouvé', but got: '\(sut.errorMessage)'")
        XCTAssertFalse(sut.isAuthenticated, "User should not be authenticated after error")
        XCTAssertFalse(sut.isLoading, "Loading should be false after error")
        
        // Reset error state before next test
        sut.dismissError()
        
        // Spécifier l'erreur précise pour tester la gestion d'erreur Firebase spécifique
        mockAuthService.configureForError(error: NSError(
            domain: "FIRAuthErrorDomain",
            code: AuthErrorCode.wrongPassword.rawValue,
            userInfo: [NSLocalizedDescriptionKey: "Wrong password"]
        ))
        
        // Test erreur mot de passe incorrect
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
            
            mockAuthService.configureForError(error: NSError(
                domain: "FIRAuthErrorDomain",
                code: errorCode,
                userInfo: [NSLocalizedDescriptionKey: "Firebase error"]
            ))
            
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
        mockAuthService.configureForError(error: customError)
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError)
        XCTAssertEqual(sut.errorMessage, "Custom error message")
    }

    // MARK: - Tests des propriétés d'image de profil
    
    func testProfileImageHandling() {
        let testImage = UIImage(systemName: "person.circle") 
        
        // Test de définition et récupération de l'image
        sut.profileImage = testImage
        XCTAssertNotNil(sut.profileImage)
        
        // Test du statut de téléchargement
        XCTAssertFalse(sut.isUploadingImage)
        sut.isUploadingImage = true
        XCTAssertTrue(sut.isUploadingImage)
    }
    
    // MARK: - Tests de validation des formulaires
    
    func testEmailValidation() {
        // Test d'emails invalides
        let invalidEmails = [
            "",                     // Vide
            "plainaddress",         // Sans @
            "@missingusername.com", // Manque nom d'utilisateur
            "user@.com",            // Domaine incomplet
            "user@domain",          // Sans TLD
            "user@domain..com"      // Double point
        ]
        
        for email in invalidEmails {
            sut.email = email
            XCTAssertFalse(mockAuthService.isValidEmail(email),
                          "Email '\(email)' ne devrait pas être valide")
            XCTAssertFalse(sut.isFormValid, 
                          "La propriété isFormValid devrait être false pour l'email '\(email)'")
        }
        
        // Test d'emails valides
        let validEmails = [
            "email@example.com",
            "firstname.lastname@domain.com",
            "email+tag@example.com",
            "firstname-lastname@domain.co.jp",
            "1234567890@domain.com"
        ]
        
        for email in validEmails {
            sut.email = email
            XCTAssertTrue(mockAuthService.isValidEmail(email),
                         "Email '\(email)' devrait être valide")
            // Nous ne pouvons pas tester isEmailValid directement car c'est une propriété privée
            // À la place, nous vérifions que l'email est accepté par le mock
        }
    }
    
    func testPasswordValidation() {
        // Test de mots de passe invalides
        let invalidPasswords = [
            "",        // Vide
            "123",     // Trop court
            "12345"    // Trop court
        ]
        
        for password in invalidPasswords {
            sut.password = password
            XCTAssertFalse(mockAuthService.isValidPassword(password),
                          "Mot de passe '\(password)' ne devrait pas être valide")
            // Nous ne pouvons pas tester isPasswordValid directement car c'est une propriété privée
            // À la place, nous vérifions que le mot de passe est rejeté par le mock
        }
        
        // Test de mots de passe valides
        let validPasswords = [
            "123456",
            "password123",
            "A_Very_Long_P@ssw0rd"
        ]
        
        for password in validPasswords {
            sut.password = password
            XCTAssertTrue(mockAuthService.isValidPassword(password),
                         "Mot de passe '\(password)' devrait être valide")
            // Nous ne pouvons pas tester isPasswordValid directement car c'est une propriété privée
            // À la place, nous vérifions que le mot de passe est accepté par le mock
        }
    }
    
    func testUsernameValidation() {
        // Le nom d'utilisateur ne devrait pas être vide
        sut.username = ""
        // Nous ne pouvons pas tester isUsernameValid directement car c'est une propriété privée
        // À la place, nous vérifions que le formulaire n'est pas valide
        XCTAssertFalse(sut.isSignUpFormValid, "Un formulaire avec nom d'utilisateur vide ne devrait pas être valide")
        
        // Test de noms d'utilisateur valides
        let validUsernames = [
            "user",
            "user123",
            "user_name",
            "UserName"
        ]
        
        for username in validUsernames {
            sut.username = username
            sut.email = "valid@example.com"
            sut.password = "password123"
            XCTAssertTrue(sut.isSignUpFormValid, "Le formulaire avec nom d'utilisateur '\(username)' devrait être valide")
        }
    }
    
    // MARK: - Tests d'état et de concurrence
    
    func testLoading() async {
        sut.isLoading = true
        XCTAssertTrue(sut.isLoading)
        
        sut.isLoading = false
        XCTAssertFalse(sut.isLoading)
    }
    
    func testErrorHandlingDirectly() {
        // Test direct du mécanisme d'erreur en accédant aux propriétés publiées
        XCTAssertFalse(sut.showingError, "showingError doit être false initialement")
        
        // Définir l'erreur manuellement dans le ViewModel en accédant directement aux propriétés publiées
        sut.errorMessage = "Test d'erreur manuel"
        sut.showingError = true
        
        XCTAssertTrue(sut.showingError, "showingError doit être true après avoir défini une erreur")
        XCTAssertEqual(sut.errorMessage, "Test d'erreur manuel", "Le message d'erreur ne correspond pas")
        
        // Tester la réinitialisation de l'erreur
        sut.dismissError()
        
        XCTAssertFalse(sut.showingError, "showingError doit être false après dismissError")
        XCTAssertEqual(sut.errorMessage, "", "Le message d'erreur doit être réinitialisé")
    }
    
    func testCompleteSignInSuccess() async {
        // Préparer le mock pour un succès
        mockAuthService.configureForSuccess()
        
        // Configurer les données d'entrée
        let testEmail = "test@example.com"
        let testPassword = "password123"
        sut.email = testEmail
        sut.password = testPassword
        
        // Exécuter le sign in
        await sut.signIn()
        
        // Vérifications
        XCTAssertTrue(mockAuthService.signInCalled, "La méthode signIn du service aurait dû être appelée")
        XCTAssertEqual(mockAuthService.lastEmailUsed, testEmail)
        XCTAssertEqual(mockAuthService.lastPasswordUsed, testPassword)
        
        // Vérifier que l'auth est réussie
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showingError)
        
        // Vérifier que les identifiants sont sauvegardés dans le keychain
        XCTAssertTrue(mockKeychainService.saveCalled)
        XCTAssertEqual(mockKeychainService.saveCalledCount, 2) // email et password
    }
    
    func testCompleteSignUpSuccess() async {
        // Préparer le mock pour un succès
        mockAuthService.configureForSuccess()
        
        // Configurer les données d'entrée
        let testEmail = "newuser@example.com"
        let testPassword = "password123"
        let testUsername = "newuser"
        sut.email = testEmail
        sut.password = testPassword
        sut.username = testUsername
        
        // Exécuter le sign up
        await sut.signUp()
        
        // Vérifications
        XCTAssertTrue(mockAuthService.signUpCalled, "La méthode signUp du service aurait dû être appelée")
        XCTAssertEqual(mockAuthService.lastEmailUsed, testEmail)
        XCTAssertEqual(mockAuthService.lastPasswordUsed, testPassword)
        // Pas de vérification directe du nom d'utilisateur car MockAuthenticationService ne trace pas les noms d'utilisateur
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showingError)
        
        // Vérifier que les identifiants sont sauvegardés dans le keychain
        XCTAssertTrue(mockKeychainService.saveCalled)
        XCTAssertEqual(mockKeychainService.saveCalledCount, 2) // email et password
    }
    
    // MARK: - Tests de concurrence et d'état
    
    func testConcurrentSignIn() async {
        sut.email = "test@example.com"
        sut.password = "password123"
        mockAuthService.configureForSuccess()
        
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
        mockAuthService.configureForSuccess()
        
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
        let customError = NSError(
            domain: "NetworkError",
            code: 500,
            userInfo: [NSLocalizedDescriptionKey: "Network timeout"]
        )
        mockAuthService.configureForError(error: customError)
        
        await sut.signIn()
        
        XCTAssertTrue(sut.showingError)
        XCTAssertEqual(sut.errorMessage, "Network timeout")
    }
}
