//
//  AuthenticationViewModelTests.swift
//  EventoriasTests
//
//  Created on 27/06/2025
//

import XCTest
import Combine
@testable import Eventorias
@MainActor
class AuthenticationViewModelTests: XCTestCase {
    // MARK: - Properties
    private var viewModel: AuthenticationViewModel!
    private var mockAuthService: MockAuthenticationService!
    private var mockKeychainService: MockKeychainService!
    private var mockStorageService: MockStorageService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAuthService = MockAuthenticationService()
        mockKeychainService = MockKeychainService()
        mockStorageService = MockStorageService()
        
        // Réinitialisation des compteurs pour que chaque test commence avec des compteurs à 0
        mockKeychainService.saveCallCount = 0
        mockKeychainService.retrieveCallCount = 0
        mockKeychainService.deleteCallCount = 0
        
        // Nettoyer UserDefaults avant chaque test pour garantir l'isolation
        UserDefaults.standard.removeObject(forKey: "lastUserEmail")
        UserDefaults.standard.removeObject(forKey: "lastUsername")
        
        viewModel = AuthenticationViewModel(
            authService: mockAuthService,
            keychainService: mockKeychainService,
            storageService: mockStorageService
        )
        cancellables = []
    }
    
    override func tearDown() {
        // Nettoyer UserDefaults après chaque test
        UserDefaults.standard.removeObject(forKey: "lastUserEmail")
        UserDefaults.standard.removeObject(forKey: "lastUsername")
        
        // Réinitialiser les mocks et libérer les ressources
        viewModel = nil
        mockAuthService = nil
        mockKeychainService = nil
        mockStorageService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1.0
    ) throws -> T.Output where T.Failure == Never {
        var result: Result<T.Output, Error>?
        let expectation = expectation(description: "Awaiting publisher")
        
        publisher
            .sink(
                receiveValue: { value in
                    result = .success(value)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)
        
        waitForExpectations(timeout: timeout)
        
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            throw error
        case .none:
            throw NSError(domain: "AuthenticationViewModelTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Publisher did not produce any value"])
        }
    }
    
    // MARK: - Initialization Tests
    
    func testInit_WhenUserIsAuthenticated_ShouldSetUserIsLoggedInToTrue() {
        // Given
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // When
        viewModel = AuthenticationViewModel(
            authService: mockAuthService,
            keychainService: mockKeychainService,
            storageService: mockStorageService
        )
        
        // Then
        XCTAssertTrue(viewModel.userIsLoggedIn)
        XCTAssertTrue(mockAuthService.isUserAuthenticatedCalled)
    }
    
    func testInit_WhenUserIsNotAuthenticated_ShouldLoadStoredCredentials() {
        // Given
        mockAuthService.isUserAuthenticatedReturnValue = false
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        mockKeychainService.retrieveResults = [
            "userEmail": testEmail,
            "userPassword": testPassword
        ]
        
        // When
        viewModel = AuthenticationViewModel(
            authService: mockAuthService,
            keychainService: mockKeychainService,
            storageService: mockStorageService
        )
        
        // Then
        XCTAssertFalse(viewModel.userIsLoggedIn)
        XCTAssertEqual(viewModel.email, testEmail)
        XCTAssertEqual(viewModel.password, testPassword)
        XCTAssertTrue(mockAuthService.isUserAuthenticatedCalled)
    }
    
    // MARK: - Sign In Tests
    
    @MainActor
    func testSignIn_WhenSuccessful_ShouldSetUserLoggedInAndStoreCredentials() async {
        // Given
        viewModel.email = "success@example.com"
        viewModel.password = "password123"
        mockAuthService.shouldThrowError = false
        
        // When
        await viewModel.signIn()
        
        // Then
        XCTAssertTrue(viewModel.userIsLoggedIn)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockAuthService.signInCalled)
        XCTAssertEqual(mockKeychainService.saveCallCount, 2) // email et password
    }
    
    @MainActor
    func testSignIn_WhenFails_ShouldSetErrorMessageAndNotLogIn() async {
        // Given
        viewModel.email = "fail@example.com"
        viewModel.password = "wrongpassword"
        mockAuthService.shouldThrowError = true
        mockAuthService.mockError = NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid credentials"])
        
        // When
        await viewModel.signIn()
        
        // Then
        XCTAssertFalse(viewModel.userIsLoggedIn)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Invalid credentials")
        XCTAssertTrue(mockAuthService.signInCalled)
        XCTAssertEqual(mockKeychainService.saveCallCount, 0) // aucune sauvegarde
    }
    
    @MainActor
    func testSignIn_ShouldUpdateLoadingState() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        
        // Create an expectation for the loading state
        let expectation = expectation(description: "Loading state should change")
        var loadingStates: [Bool] = []
        
        // When
        viewModel.$isLoading
            .sink { isLoading in
                loadingStates.append(isLoading)
                if loadingStates.count >= 3 { // initial + loading + finished
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Start the sign in process
        Task {
            await viewModel.signIn()
        }
        
        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(loadingStates[0], false) // Initial state
        XCTAssertEqual(loadingStates[1], true)  // During sign in
        XCTAssertEqual(loadingStates[2], false) // After sign in
    }
    
    // MARK: - Sign Up Tests
    
    @MainActor
    func testSignUp_WhenUsernameIsEmpty_ShouldSetErrorMessage() async {
        // Given
        viewModel.email = "test@example.com"
        viewModel.password = "password123"
        viewModel.username = "" // Empty username
        
        // When
        await viewModel.signUp()
        
        // Then
        XCTAssertFalse(viewModel.userIsLoggedIn)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Le nom d'utilisateur est requis")
        XCTAssertFalse(mockAuthService.signUpCalled)
    }
    
    @MainActor
    func testSignUp_WhenSuccessful_ShouldCreateUserAndUpdateProfile() async {
        // Given
        viewModel.email = "newuser@example.com"
        viewModel.password = "password123"
        viewModel.username = "New User"
        mockAuthService.shouldThrowError = false
        let mockUser = MockUser(uid: "test-uid", email: "newuser@example.com", displayName: "New User")
        mockAuthService.currentUserMock = mockUser
        
        // When
        await viewModel.signUp()
        
        // Then
        XCTAssertTrue(viewModel.userIsLoggedIn)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertTrue(mockAuthService.updateUserProfileCalled)
        XCTAssertEqual(mockKeychainService.saveCallCount, 2) // email et password
    }
    
    @MainActor
    func testSignUp_WithProfileImage_ShouldUploadImageAndUpdateProfile() async {
        // Given
        viewModel.email = "newuser@example.com"
        viewModel.password = "password123"
        viewModel.username = "New User"
        viewModel.profileImage = UIImage(systemName: "person.circle") // Simuler une image
        mockAuthService.shouldThrowError = false
        let mockUser = MockUser(uid: "test-uid", email: "newuser@example.com", displayName: "New User")
        mockAuthService.currentUserMock = mockUser
        mockStorageService.mockDownloadURLString = "https://example.com/profile.jpg"
        
        // When
        await viewModel.signUp()
        
        // Then
        XCTAssertTrue(viewModel.userIsLoggedIn)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertTrue(mockAuthService.updateUserProfileCalled)
        XCTAssertTrue(mockStorageService.uploadImageCalled)
        XCTAssertEqual(mockKeychainService.saveCallCount, 2) // email et password
    }
    
    @MainActor
    func testSignUp_WhenFails_ShouldSetErrorMessageAndNotLogIn() async {
        // Given
        viewModel.email = "invalid@example.com"
        viewModel.password = "weak"
        viewModel.username = "Invalid User"
        mockAuthService.shouldThrowError = true
        mockAuthService.mockError = NSError(domain: "Auth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Weak password"])
        
        // When
        await viewModel.signUp()
        
        // Then
        XCTAssertFalse(viewModel.userIsLoggedIn)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "Weak password")
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertFalse(mockAuthService.updateUserProfileCalled)
        XCTAssertEqual(mockKeychainService.saveCallCount, 0) // aucune sauvegarde
    }
    
    // MARK: - Sign Out Tests
    
    @MainActor
    func testSignOut_WhenSuccessful_ShouldClearCredentialsAndSetUserLoggedOut() async {
        // Given
        let testEmail = "user@example.com"
        let testPassword = "password123"
        viewModel.email = testEmail
        viewModel.password = testPassword
        viewModel.userIsLoggedIn = true
        mockAuthService.shouldThrowError = false
        
        // Simule que l'email et le mot de passe sont déjà dans le Keychain
        // pour que la suppression puisse fonctionner
        try? mockKeychainService.save(testEmail, for: "userEmail")
        try? mockKeychainService.save(testPassword, for: "userPassword")
        // Réinitialiser le compteur après la sauvegarde
        mockKeychainService.deleteCallCount = 0
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertFalse(viewModel.userIsLoggedIn)
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertEqual(mockKeychainService.deleteCallCount, 2) // email et password
    }
    
    @MainActor
    func testSignOut_WhenFails_ShouldSetErrorMessage() async {
        // Given
        viewModel.userIsLoggedIn = true
        mockAuthService.shouldThrowError = true
        mockAuthService.mockError = NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When
        await viewModel.signOut()
        
        // Then
        XCTAssertEqual(viewModel.errorMessage, "Network error")
        XCTAssertTrue(mockAuthService.signOutCalled)
    }
    
    @MainActor
    func testSignOutWithoutClearingForm_ShouldKeepFormData() async {
        // Given
        let testEmail = "keep@example.com"
        let testPassword = "keeppassword"
        viewModel.email = testEmail
        viewModel.password = testPassword
        viewModel.userIsLoggedIn = true
        
        // Simule que l'email et le mot de passe sont déjà dans le Keychain
        // pour que la suppression puisse fonctionner
        try? mockKeychainService.save(testEmail, for: "userEmail")
        try? mockKeychainService.save(testPassword, for: "userPassword")
        // Réinitialiser le compteur après la sauvegarde
        mockKeychainService.deleteCallCount = 0
        
        // When
        await viewModel.signOutWithoutClearingForm()
        
        // Then
        XCTAssertFalse(viewModel.userIsLoggedIn)
        XCTAssertEqual(viewModel.email, testEmail) // Email conservé
        XCTAssertEqual(viewModel.password, testPassword) // Mot de passe conservé
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertEqual(mockKeychainService.deleteCallCount, 2) // email et password supprimés du keychain
    }
    
    // MARK: - Credential Storage Tests
    
    func testStoreCredentialsExplicit_WhenSuccessful_ShouldSaveToKeychain() {
        // Given
        let testEmail = "store@example.com"
        let testPassword = "storepassword"
        
        // When
        viewModel.storeCredentialsExplicit(email: testEmail, password: testPassword)
        
        // Then
        XCTAssertEqual(mockKeychainService.saveCallCount, 2) // email et password
        XCTAssertEqual(mockKeychainService.savedValues["userEmail"], "store@example.com")
        XCTAssertEqual(mockKeychainService.savedValues["userPassword"], testPassword)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testStoreCredentialsExplicit_WhenFails_ShouldSetErrorMessage() {
        // Given
        let testEmail = "store@example.com"
        let testPassword = "storepassword"
        mockKeychainService.shouldThrowOnSave = true
        mockKeychainService.saveError = KeychainError.creationFailed(1)
        
        // When
        viewModel.storeCredentialsExplicit(email: testEmail, password: testPassword)
        
        // Then
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertTrue(viewModel.errorMessage!.contains("Could not save credentials"))
    }
    
    func testLoadStoredCredentials_WhenCredentialsExist_ShouldPopulateEmailAndPassword() {
        // Given
        let testEmail = "stored@example.com"
        let testPassword = "storedpassword"
        mockKeychainService.retrieveResults = [
            "userEmail": testEmail,
            "userPassword": testPassword
        ]
        
        // Réinitialiser le compteur d'appels avant le test pour ignorer ceux de l'initialisation
        mockKeychainService.retrieveCallCount = 0
        
        // When
        viewModel.loadStoredCredentials()
        
        // Then
        XCTAssertEqual(viewModel.email, "stored@example.com")
        XCTAssertEqual(viewModel.password, "storedpassword")
        XCTAssertEqual(mockKeychainService.retrieveCallCount, 2) // email et password
    }
    
    func testLoadStoredCredentials_WhenCredentialsDontExist_ShouldClearEmailAndPassword() {
        // Given
        viewModel.email = "oldEmail@example.com"
        viewModel.password = "oldPassword"
        mockKeychainService.shouldThrowOnRetrieve = true
        
        // When
        viewModel.loadStoredCredentials()
        
        // Then
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
    }
    
    // MARK: - Quick Sign In Tests
    
    @MainActor
    func testQuickSignIn_WhenCredentialsExist_ShouldCallSignIn() async {
        // Given
        viewModel.email = "quick@example.com"
        viewModel.password = "quickpassword"
        
        // When
        await viewModel.quickSignIn()
        
        // Then
        XCTAssertTrue(mockAuthService.signInCalled)
    }
    
    @MainActor
    func testQuickSignIn_WhenCredentialsAreEmpty_ShouldNotCallSignIn() async {
        // Given
        viewModel.email = ""
        viewModel.password = "quickpassword"
        
        // When
        await viewModel.quickSignIn()
        
        // Then
        XCTAssertFalse(mockAuthService.signInCalled)
        
        // Test with empty password
        viewModel.email = "quick@example.com"
        viewModel.password = ""
        
        await viewModel.quickSignIn()
        
        XCTAssertFalse(mockAuthService.signInCalled)
    }
    
    // MARK: - Error Handling Tests
    
    func testDismissError_ShouldClearErrorMessage() {
        // Given
        viewModel.errorMessage = "Test error message"
        
        // When
        viewModel.dismissError()
        
        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
}
