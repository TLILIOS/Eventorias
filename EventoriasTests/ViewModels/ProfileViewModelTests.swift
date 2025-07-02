//
//  ProfileViewModelTests.swift
//  EventoriasTests
//
//  Created on 27/06/2025
//

import XCTest
import Combine
import SwiftUI
@testable import Eventorias
@MainActor
class ProfileViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: ProfileViewModel!
    private var mockAuthViewModel: MockAuthenticationViewModel!
    private var mockAuthService: MockAuthenticationService!
    private var mockStorageService: MockStorageService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockAuthViewModel = MockAuthenticationViewModel()
        mockAuthService = MockAuthenticationService()
        mockStorageService = MockStorageService()
        viewModel = ProfileViewModel(
            authViewModel: mockAuthViewModel,
            authService: mockAuthService,
            storageService: mockStorageService
        )
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockAuthViewModel = nil
        mockAuthService = nil
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
            throw NSError(domain: "ProfileViewModelTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Publisher did not produce any value"])
        }
    }
    
    // MARK: - Initialization Tests
    
    func testInit_ShouldSetupAuthStateObserver() {
        // Given & When - le setup fait déjà l'initialization
        
        // Then
        // Nous ne pouvons pas vraiment tester si l'observateur est mis en place,
        // mais nous pouvons vérifier que l'état initial est correct
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.displayName, "")
        XCTAssertEqual(viewModel.email, "")
        XCTAssertNil(viewModel.avatarUrl)
    }
    
    // MARK: - Load User Profile Tests
    
    @MainActor
    func testLoadUserProfile_WhenUserIsAuthenticated_ShouldLoadUserData() {
        // Given
        let mockUser = MockUser(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User"
        )
        mockAuthService.currentUserMock = mockUser
        
        // When
        viewModel.loadUserProfile()
        
        // Then
        XCTAssertEqual(viewModel.displayName, "Test User")
        XCTAssertEqual(viewModel.email, "test@example.com")
        XCTAssertTrue(mockAuthService.getCurrentUserCalled)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    @MainActor
    func testLoadUserProfile_WhenUserHasPhotoURL_ShouldSetAvatarUrl() {
        // Given
        let photoURLString = "https://example.com/photo.jpg"
        let mockUser = MockUser(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: URL(string: photoURLString)
        )
        mockAuthService.currentUserMock = mockUser
        
        // When
        viewModel.loadUserProfile()
        
        // Then
        XCTAssertEqual(viewModel.avatarUrl?.absoluteString, photoURLString)
    }
    
    @MainActor
    func testLoadUserProfile_WhenUserHasNoPhotoURL_ShouldTryToFetchFromStorage() async throws {
        // Given
        let mockUser = MockUser(
            uid: "test-uid",
            email: "test@example.com",
            displayName: "Test User"
        )
        mockAuthService.currentUserMock = mockUser
        let expectedURLString = "https://example.com/profile.jpg"
        mockStorageService.mockDownloadURL = URL(string: expectedURLString)!
        
        // When
        viewModel.loadUserProfile()
        
        // Attendons suffisamment longtemps pour que la tâche asynchrone s'exécute complètement
        // Au lieu de Task.yield(), utilisons un délai plus long pour s'assurer que la tâche est terminée
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconde
        
        // Then
        XCTAssertTrue(mockStorageService.getDownloadURLCalled, "La méthode getDownloadURL aurait dû être appelée")
    }
    
    @MainActor
    func testLoadUserProfile_WhenNoUser_ShouldSetErrorMessage() {
        // Given
        mockAuthService.currentUserMock = nil
        
        // When
        viewModel.loadUserProfile()
        
        // Then
        XCTAssertTrue(viewModel.errorMessage.contains("Aucun utilisateur"))
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Update Display Name Tests
    
    @MainActor
    func testUpdateDisplayName_WhenSuccessful_ShouldUpdateDisplayName() async {
        // Given
        let newName = "Nouveau Nom"
        
        // When
        await viewModel.updateDisplayName(newName)
        
        // Then
        XCTAssertEqual(viewModel.displayName, newName)
        XCTAssertTrue(mockAuthService.updateUserProfileCalled)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "")
    }
    
    @MainActor
    func testUpdateDisplayName_WhenEmpty_ShouldSetErrorMessage() async {
        // Given
        let emptyName = "   "
        viewModel.displayName = "Ancien Nom" // Définir une valeur initiale pour tester qu'elle n'est pas modifiée
        
        // When
        await viewModel.updateDisplayName(emptyName)
        
        // Then
        XCTAssertEqual(viewModel.displayName, "Ancien Nom", "Le nom d'affichage ne devrait pas être modifié")
        XCTAssertFalse(mockAuthService.updateUserProfileCalled, "updateUserProfile ne devrait pas être appelé avec un nom vide")
        XCTAssertTrue(viewModel.errorMessage.contains("cannot be empty"), "Un message d'erreur approprié devrait être défini")
        XCTAssertFalse(viewModel.isLoading, "isLoading devrait être false après l'opération")
    }
    
    @MainActor
    func testUpdateDisplayName_WhenServiceThrowsError_ShouldSetErrorMessage() async {
        // Given
        mockAuthService.shouldThrowError = true
        mockAuthService.mockError = NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to update profile"])
        
        // When
        await viewModel.updateDisplayName("Nouveau Nom")
        
        // Then
        XCTAssertTrue(mockAuthService.updateUserProfileCalled)
        XCTAssertTrue(viewModel.errorMessage.contains("Failed to update profile"))
        XCTAssertFalse(viewModel.isLoading)
    }
    
    // MARK: - Notification Preference Tests
    
    func testUpdateNotificationPreferences_ShouldUpdatePreferenceValue() {
        // Given
        viewModel.notificationsEnabled = true
        
        // When
        viewModel.updateNotificationPreferences(enabled: false)
        
        // Then
        XCTAssertFalse(viewModel.notificationsEnabled)
    }
    
    // MARK: - Authentication ViewModel Update Tests
    
    @MainActor
    func testUpdateAuthenticationViewModel_ShouldUpdateRefAndReloadProfile() {
        // Given
        let newMockAuthViewModel = MockAuthenticationViewModel()
        
        // When
        viewModel.updateAuthenticationViewModel(newMockAuthViewModel)
        
        // Then
        // Difficile de tester directement le changement de référence,
        // mais nous pouvons vérifier que loadUserProfile a été appelé en regardant
        // si getCurrentUser a été appelé
        XCTAssertTrue(mockAuthService.getCurrentUserCalled)
    }
    
    // MARK: - Sign Out Tests
    
    @MainActor
    func testSignOut_WhenSuccessful_ShouldCallAuthServiceAndAuthViewModel() async {
        // Given
        // Le setup par défaut est suffisant
        
        // When
        viewModel.signOut()
        
        // Then
        XCTAssertTrue(mockAuthService.signOutCalled)
        
        // Attendons un peu pour que la tâche asynchrone s'exécute
        await Task.yield()
        
        // Vérifions que le ViewModel d'authentification a été appelé pour se déconnecter
        XCTAssertTrue(mockAuthViewModel.signOutCalled)
        XCTAssertEqual(viewModel.errorMessage, "")
    }
    
    @MainActor
    func testSignOut_WhenFails_ShouldSetErrorMessage() {
        // Given
        mockAuthService.shouldThrowError = true
        mockAuthService.mockError = NSError(domain: "Auth", code: 500, userInfo: [NSLocalizedDescriptionKey: "Network error"])
        
        // When
        viewModel.signOut()
        
        // Then
        XCTAssertTrue(mockAuthService.signOutCalled)
        XCTAssertTrue(viewModel.errorMessage.contains("Failed to sign out"))
    }
    
    // MARK: - Try Alternative Image Formats Tests (DEBUG Only)
    
    #if DEBUG
    @MainActor
    func testTryAlternativeImageFormats_WhenURLFound_ShouldSetAvatarUrl() async {
        // Given
        let expectedURL = URL(string: "https://example.com/profile.png")!
        mockStorageService.mockDownloadURL = expectedURL
        
        // When
        let task = viewModel.tryAlternativeImageFormatForTesting(userID: "test-uid")
        await task.value // Attendre que la tâche se termine
        
        // Then
        XCTAssertEqual(viewModel.avatarUrl, expectedURL)
        XCTAssertTrue(mockStorageService.getDownloadURLCalled)
    }
    
    @MainActor
    func testTryAlternativeImageFormats_WhenAllExtensionsFail_ShouldNotSetAvatarUrl() async {
        // Given
        mockStorageService.shouldThrowError = true
        
        // When
        let task = viewModel.tryAlternativeImageFormatForTesting(userID: "test-uid")
        await task.value // Attendre que la tâche se termine
        
        // Then
        XCTAssertNil(viewModel.avatarUrl)
        XCTAssertTrue(mockStorageService.getDownloadURLCalled)
    }
    #endif
}
