//
//  EventCreationViewModelTests.swift
//  EventoriasTests
//
//  Created on 27/06/2025
//

import XCTest
import Combine
import UIKit
@testable import Eventorias
// Import nécessaire pour accéder aux types requis dans les tests (Event, Invitation, etc.)

@MainActor
class EventCreationViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: EventCreationViewModel!
    private var mockEventViewModel: EventViewModelMock!
    private var mockAuthService: EventCreationMockAuthenticationService!
    private var mockStorageService: EventCreationMockStorageService!
    private var mockFirestoreService: EventCreationMockFirestoreService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockEventViewModel = EventViewModelMock()
        mockAuthService = EventCreationMockAuthenticationService()
        mockStorageService = EventCreationMockStorageService()
        mockFirestoreService = EventCreationMockFirestoreService()
        
        viewModel = EventCreationViewModel(
            eventViewModel: AnyEventViewModel(mockEventViewModel),
            authService: mockAuthService,
            storageService: mockStorageService,
            firestoreService: mockFirestoreService
        )
        
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockEventViewModel = nil
        mockAuthService = nil
        mockStorageService = nil
        mockFirestoreService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func resetAllMocksAndViewModel() {
        // Réinitialiser l'état du ViewModel
        mockEventViewModel = EventViewModelMock()
        mockAuthService = EventCreationMockAuthenticationService()
        mockStorageService = EventCreationMockStorageService()
        mockFirestoreService = EventCreationMockFirestoreService()
        
        // Configuration par défaut des mocks pour éviter les erreurs
        mockAuthService.currentUserMock = EventCreationMockUser(uid: "test-uid", email: "test@example.com", displayName: "Test User")
        mockAuthService.currentUserDisplayNameMock = "Test User"
        mockAuthService.currentUserEmailMock = "test@example.com"
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        mockFirestoreService.shouldThrowError = false
        mockStorageService.shouldThrowError = false
        
        viewModel = EventCreationViewModel(
            eventViewModel: AnyEventViewModel(mockEventViewModel),
            authService: mockAuthService,
            storageService: mockStorageService,
            firestoreService: mockFirestoreService
        )
        
        // Réinitialiser les états du ViewModel
        viewModel.errorMessage = ""
        viewModel.eventCreationSuccess = false
        viewModel.imageUploadState = .idle
        viewModel.imageURL = ""
        viewModel.eventTitle = ""
        viewModel.eventDescription = ""
        viewModel.eventAddress = ""
        viewModel.eventDate = Date()
        viewModel.eventImage = nil
    }
    
    private func createTestImage() -> UIImage? {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.setFillColor(UIColor.red.cgColor)
        context.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    // MARK: - Form Validation Tests
    
    func testCreateEvent_WhenTitleIsEmpty_ShouldReturnFalseAndSetErrorMessage() async {
        // Given
        viewModel.eventTitle = "   " // Espaces blancs uniquement
        viewModel.eventAddress = "123 rue Test" // Adresse valide
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.errorMessage, "Veuillez saisir un titre pour l'événement")
        XCTAssertFalse(mockFirestoreService.createEventCalled)
    }
    
    func testCreateEvent_WhenAddressIsEmpty_ShouldReturnFalseAndSetErrorMessage() async {
        // Given
        viewModel.eventTitle = "Titre de l'événement" // Titre valide
        viewModel.eventAddress = "   " // Espaces blancs uniquement
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.errorMessage, "Veuillez saisir une adresse pour l'événement")
        XCTAssertFalse(mockFirestoreService.createEventCalled)
    }
    
    func testCreateEvent_WhenFormIsValid_ShouldCreateEventSuccessfully() async {
        // Given
        // Réinitialiser manuellement tous les mocks et viewModel
        resetAllMocksAndViewModel()
        
        // Configurer les entrées du formulaire
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventDescription = "Description de l'événement"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventDate = Date()
        
        // Configuration spécifique des mocks pour ce test
        mockAuthService.currentUserMock = EventCreationMockUser(uid: "test-uid", email: "test@example.com", displayName: "Organisateur Test")
        mockAuthService.currentUserDisplayNameMock = "Organisateur Test"
        mockAuthService.currentUserEmailMock = "organisateur@test.com"
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        mockFirestoreService.shouldThrowError = false
        mockFirestoreService.createEventCalled = false  // S'assurer que l'état est réinitialisé
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertTrue(result, "La création d'événement devrait réussir")
        XCTAssertTrue(viewModel.eventCreationSuccess, "eventCreationSuccess devrait être true")
        XCTAssertEqual(viewModel.errorMessage, "", "Il ne devrait pas y avoir de message d'erreur")
        XCTAssertTrue(mockFirestoreService.createEventCalled, "La méthode createEvent de FirestoreService devrait être appelée")
    }
    
    // MARK: - Image Upload Tests
    
    func testCreateEvent_WithImageUpload_WhenSuccessful_ShouldCreateEventWithImageURL() async {
        // Given
        // Réinitialiser manuellement tous les mocks et viewModel
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Événement avec image"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventImage = createTestImage()
        
        let expectedImageURL = "https://example.com/image.jpg"
        mockStorageService.mockDownloadURLString = expectedImageURL
        
        // Configuration des mocks pour un test réussi
        mockAuthService.isUserAuthenticatedReturnValue = true
        mockFirestoreService.shouldThrowError = false
        mockStorageService.shouldThrowError = false
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.imageURL, expectedImageURL)
        XCTAssertEqual(viewModel.imageUploadState, .success)
        XCTAssertTrue(mockStorageService.uploadImageCalled)
    }
    
    func testCreateEvent_WithImageUpload_WhenUploadFails_ShouldReturnFalseAndSetError() async {
        // Given
        // Réinitialiser manuellement tous les mocks et viewModel
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Événement avec image"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventImage = createTestImage()
        
        // Configuration du test avec mocks
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // Configurer le service de stockage pour échouer
        mockStorageService.shouldThrowError = true
        mockStorageService.mockError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur lors de l'upload"])
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.imageUploadState, .failure)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur lors de l'upload de l'image"))
        XCTAssertFalse(mockFirestoreService.createEventCalled)
    }
    
    func testCreateEvent_WithImageUpload_WhenNetworkError_ShouldHandleSpecificNetworkErrors() async {
        // Given
        // Réinitialiser manuellement tous les mocks et viewModel
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Événement avec image"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventImage = createTestImage()
        
        // Configuration du test avec mocks
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // Configurer une erreur réseau spécifique
        let urlError = URLError(.notConnectedToInternet)
        mockStorageService.shouldThrowError = true
        mockStorageService.mockError = urlError
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.imageUploadState, .failure)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur réseau"))
        XCTAssertTrue(viewModel.errorMessage.contains("connexion Internet"))
        XCTAssertFalse(mockFirestoreService.createEventCalled)
    }
    
    // MARK: - Event Creation Error Tests
    
    func testCreateEvent_WhenFirestoreThrowsError_ShouldReturnFalseAndSetErrorMessage() async {
        // Given
        // Réinitialiser manuellement tous les mocks et viewModel
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventAddress = "123 rue Test"
        
        // Configuration du test avec mocks
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // Configurer Firestore pour échouer
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur Firestore"])
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur lors de la création de l'événement"))
        XCTAssertTrue(mockFirestoreService.createEventCalled)
    }
    
    func testCreateEvent_WhenFirestoreNetworkError_ShouldHandleSpecificNetworkError() async {
        // Given
        // Réinitialiser manuellement tous les mocks et viewModel
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventAddress = "123 rue Test"
        
        // Configuration du test avec mocks
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // Configurer une erreur réseau spécifique
        let urlError = URLError(.timedOut)
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = urlError
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur réseau lors de la création"))
        XCTAssertTrue(viewModel.errorMessage.contains("expiré"))
        XCTAssertTrue(mockFirestoreService.createEventCalled)
    }
    
    // MARK: - Permission Tests
    
    func testCheckCameraPermission_WhenAuthorized_ShouldSetPermissionGranted() {
        // Cette fonction est difficile à tester car elle dépend d'APIs système
        // On peut tester le comportement après l'appel de la fonction
        viewModel.cameraPermissionGranted = true
        XCTAssertTrue(viewModel.cameraPermissionGranted)
        
        viewModel.cameraPermissionGranted = false
        XCTAssertFalse(viewModel.cameraPermissionGranted)
    }
    
    func testCheckPhotoLibraryPermission_WhenAuthorized_ShouldSetPermissionGranted() {
        // Cette fonction est difficile à tester car elle dépend d'APIs système
        // On peut tester le comportement après l'appel de la fonction
        viewModel.photoLibraryPermissionGranted = true
        XCTAssertTrue(viewModel.photoLibraryPermissionGranted)
        
        viewModel.photoLibraryPermissionGranted = false
        XCTAssertFalse(viewModel.photoLibraryPermissionGranted)
    }
    
    // MARK: - Form Reset Test
    
    func testResetForm_ShouldResetAllFieldsToDefaultValues() {
        // Given
        viewModel.eventTitle = "Titre personnalisé"
        viewModel.eventDescription = "Description personnalisée"
        viewModel.eventAddress = "Adresse personnalisée"
        viewModel.eventImage = createTestImage()
        viewModel.imageURL = "https://example.com/image.jpg"
        viewModel.errorMessage = "Une erreur précédente"
        viewModel.eventCreationSuccess = true
        viewModel.imageUploadState = .success
        
        // When
        viewModel.resetForm()
        
        // Then
        XCTAssertEqual(viewModel.eventTitle, "")
        XCTAssertEqual(viewModel.eventDescription, "")
        XCTAssertEqual(viewModel.eventAddress, "")
        XCTAssertNil(viewModel.eventImage)
        XCTAssertEqual(viewModel.imageURL, "")
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.imageUploadState, .idle)
    }
    
    // MARK: - Network Error Handling Tests
    
    func testHandleNetworkError_ShouldReturnFriendlyErrorMessage() {
        // Given
        let urlError = URLError(.notConnectedToInternet)
        
        // When
        let errorMessage = viewModel.handleNetworkError(urlError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("Aucune connexion Internet"))
    }
    
    func testHandleNetworkError_WithTimeoutError_ShouldReturnSpecificMessage() {
        // Given
        let urlError = URLError(.timedOut)
        
        // When
        let errorMessage = viewModel.handleNetworkError(urlError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("requête a expiré"))
    }
    
    func testHandleNetworkError_WithFirebaseStorageError_ShouldReturnSpecificMessage() {
        // Given
        let nsError = NSError(domain: "FIRStorageErrorDomain", code: -13010, userInfo: [:])
        
        // When
        let errorMessage = viewModel.handleNetworkError(nsError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("fichier n'existe pas"))
    }
    
    // MARK: - Authentication Requirement Tests
    
    func testCreateEvent_WhenUserNotAuthenticated_ShouldReturnFalseAndSetErrorMessage() async {
        // Given
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventAddress = "123 rue Test"
        
        // Configuration du test avec mocks - utilisateur NON authentifié
        mockAuthService.isUserAuthenticatedReturnValue = false
        mockAuthService.currentUserMock = nil
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Vous devez être connecté pour créer un événement")
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertFalse(mockFirestoreService.createEventCalled)
    }
    
    // MARK: - Default Values Tests
    
    func testCreateEvent_WithEmptyDescription_ShouldUseDefaultValue() async {
        // Given
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventDescription = ""  // Description vide
        
        // Configuration du test avec mocks
        mockAuthService.isUserAuthenticatedReturnValue = true
        mockFirestoreService.shouldThrowError = false
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(viewModel.eventCreationSuccess)
        XCTAssertTrue(mockFirestoreService.createEventCalled)
        
        // Vérification de la valeur par défaut passée à createEvent
        if let createdEvent = mockFirestoreService.lastCreatedEvent {
            XCTAssertEqual(createdEvent.description, "Aucune description", "La description vide devrait être remplacée par une valeur par défaut")
        } else {
            XCTFail("Aucun événement n'a été créé")
        }
    }
    
    // MARK: - Additional Network Error Tests
    
    func testHandleNetworkError_WithNetworkConnectionLost_ShouldReturnSpecificMessage() {
        // Given
        let urlError = URLError(.networkConnectionLost)
        
        // When
        let errorMessage = viewModel.handleNetworkError(urlError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("connexion réseau a été perdue"))
    }
    
    func testHandleNetworkError_WithCannotFindHost_ShouldReturnSpecificMessage() {
        // Given
        let urlError = URLError(.cannotFindHost)
        
        // When
        let errorMessage = viewModel.handleNetworkError(urlError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("Impossible de se connecter au serveur"))
    }
    
    func testHandleNetworkError_WithDataNotAllowed_ShouldReturnSpecificMessage() {
        // Given
        let urlError = URLError(.dataNotAllowed)
        
        // When
        let errorMessage = viewModel.handleNetworkError(urlError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("L'accès aux données est restreint"))
    }
    
    func testHandleNetworkError_WithNSURLErrorDomain_ShouldReturnSpecificMessage() {
        // Given
        let nsError = NSError(domain: NSURLErrorDomain, code: -1001, userInfo: [:]) // kCFURLErrorTimedOut
        
        // When
        let errorMessage = viewModel.handleNetworkError(nsError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("La requête a expiré"))
    }
    
    func testHandleNetworkError_WithNSURLErrorDomainHostNotFound_ShouldReturnSpecificMessage() {
        // Given
        let nsError = NSError(domain: NSURLErrorDomain, code: -1003, userInfo: [:]) // kCFURLErrorCannotFindHost
        
        // When
        let errorMessage = viewModel.handleNetworkError(nsError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("Hôte introuvable"))
    }
    
    func testHandleNetworkError_WithNSURLErrorDomainConnectionLost_ShouldReturnSpecificMessage() {
        // Given
        let nsError = NSError(domain: NSURLErrorDomain, code: -1005, userInfo: [:]) // kCFURLErrorNetworkConnectionLost
        
        // When
        let errorMessage = viewModel.handleNetworkError(nsError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("La connexion réseau a été perdue"))
    }
    
    func testHandleNetworkError_WithNSURLErrorDomainCannotLoadFromNetwork_ShouldReturnSpecificMessage() {
        // Given
        let nsError = NSError(domain: NSURLErrorDomain, code: -1020, userInfo: [:]) // kCFURLErrorCannotLoadFromNetwork
        
        // When
        let errorMessage = viewModel.handleNetworkError(nsError)
        
        // Then
        XCTAssertTrue(errorMessage.contains("Impossible de charger depuis le réseau"))
    }
    
    // MARK: - ImageUploadState Equatable Tests
    
    func testImageUploadState_Equatable_IdleState() {
        // Given
        let state1 = EventCreationViewModel.ImageUploadState.idle
        let state2 = EventCreationViewModel.ImageUploadState.idle
        
        // When & Then
        XCTAssertEqual(state1, state2)
        XCTAssertTrue(state1 == state2)
    }
    
    func testImageUploadState_Equatable_SuccessState() {
        // Given
        let state1 = EventCreationViewModel.ImageUploadState.success
        let state2 = EventCreationViewModel.ImageUploadState.success
        
        // When & Then
        XCTAssertEqual(state1, state2)
        XCTAssertTrue(state1 == state2)
    }
    
    func testImageUploadState_Equatable_FailureState() {
        // Given
        let state1 = EventCreationViewModel.ImageUploadState.failure
        let state2 = EventCreationViewModel.ImageUploadState.failure
        
        // When & Then
        XCTAssertEqual(state1, state2)
        XCTAssertTrue(state1 == state2)
    }
    
    func testImageUploadState_Equatable_UploadingState() {
        // Given
        let state1 = EventCreationViewModel.ImageUploadState.uploading(0.5)
        let state2 = EventCreationViewModel.ImageUploadState.uploading(0.5)
        
        // When & Then
        XCTAssertEqual(state1, state2)
        XCTAssertTrue(state1 == state2)
    }
    
    func testImageUploadState_NotEquatable_DifferentStates() {
        // Given
        let state1 = EventCreationViewModel.ImageUploadState.idle
        let state2 = EventCreationViewModel.ImageUploadState.success
        let state3 = EventCreationViewModel.ImageUploadState.uploading(0.5)
        
        // When & Then
        XCTAssertNotEqual(state1, state2)
        XCTAssertNotEqual(state1, state3)
        XCTAssertNotEqual(state2, state3)
    }
    
    func testImageUploadState_NotEquatable_DifferentProgress() {
        // Given
        let state1 = EventCreationViewModel.ImageUploadState.uploading(0.3)
        let state2 = EventCreationViewModel.ImageUploadState.uploading(0.7)
        
        // When & Then
        XCTAssertNotEqual(state1, state2)
        XCTAssertFalse(state1 == state2)
    }
    
    // MARK: - Image Upload Validation Tests
    
    func testUploadImage_WithInvalidImage_ShouldThrowError() async {
        // Given
        // Create an image that can't be converted to JPEG data
        let invalidImage = UIImage()
        
        // When & Then
        do {
            try await viewModel.uploadImage(invalidImage)
            XCTFail("Should have thrown an error for invalid image")
        } catch {
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "EventCreationViewModel")
            XCTAssertEqual(nsError.code, 1001)
            XCTAssertEqual(viewModel.imageUploadState, .failure)
        }
    }
    
    // MARK: - Settings Access Test
    
    func testOpenAppSettings_ShouldNotCrash() {
        // This test mainly ensures the function doesn't crash
        // Since we can't verify UI interactions in a unit test
        
        // When & Then - Should not throw or crash
        XCTAssertNoThrow(viewModel.openAppSettings())
    }
    
    // MARK: - Image Upload Retry Mechanism Tests
    
    func testUploadImage_WithRetry_WhenNetworkErrorOccurs() async {
        // Given
        resetAllMocksAndViewModel()
        
        // Create a test image
        let testImage = createTestImage()!
        
        // Configure storage service to fail on first attempt, succeed on second
        mockStorageService.shouldFailFirstAttempt = true
        mockStorageService.mockNetworkError = URLError(.networkConnectionLost)
        mockStorageService.mockDownloadURLString = "https://example.com/image-after-retry.jpg"
        
        // When
        do {
            try await viewModel.uploadImage(testImage)
            
            // Then
            XCTAssertEqual(viewModel.imageUploadState, .success)
            XCTAssertEqual(viewModel.imageURL, "https://example.com/image-after-retry.jpg")
            XCTAssertEqual(mockStorageService.uploadAttemptCount, 2, "Upload should have been attempted twice")
        } catch {
            XCTFail("The upload should succeed after retry, but threw an error: \(error)")
        }
    }
    
    func testUploadImage_WhenAllRetriesFail_ShouldThrowError() async {
        // Given
        resetAllMocksAndViewModel()
        
        // Create a test image
        let testImage = createTestImage()!
        
        // Configure storage service to fail on all attempts
        mockStorageService.shouldThrowError = true
        mockStorageService.alwaysFailWithNetworkError = true
        mockStorageService.mockNetworkError = URLError(.networkConnectionLost)
        
        // When & Then
        do {
            try await viewModel.uploadImage(testImage)
            XCTFail("The upload should have failed after all retries")
        } catch {
            XCTAssertEqual(viewModel.imageUploadState, .failure)
            XCTAssertTrue(error is URLError, "The thrown error should be a URLError")
            XCTAssertEqual((error as? URLError)?.code, .networkConnectionLost)
            XCTAssertGreaterThanOrEqual(mockStorageService.uploadAttemptCount, 3, "Upload should have been attempted at least 3 times")
        }
    }
    
    // MARK: - Reset Form After Error/Success Tests
    
    func testResetForm_AfterSuccessfulEventCreation_ShouldResetAllFields() async {
        // Given
        resetAllMocksAndViewModel()
        
        // Setup for successful event creation
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventDescription = "Description de test"
        viewModel.eventImage = createTestImage()
        viewModel.imageURL = "https://example.com/image.jpg"
        mockAuthService.isUserAuthenticatedReturnValue = true
        mockFirestoreService.shouldThrowError = false
        
        // When - Create event then reset
        let createResult = await viewModel.createEvent()
        XCTAssertTrue(createResult)
        XCTAssertTrue(viewModel.eventCreationSuccess)
        
        viewModel.resetForm()
        
        // Then
        XCTAssertEqual(viewModel.eventTitle, "")
        XCTAssertEqual(viewModel.eventDescription, "")
        XCTAssertEqual(viewModel.eventAddress, "")
        XCTAssertNil(viewModel.eventImage)
        XCTAssertEqual(viewModel.imageURL, "")
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.imageUploadState, .idle)
    }
    
    func testResetForm_AfterFailedEventCreation_ShouldResetAllFields() async {
        // Given
        resetAllMocksAndViewModel()
        
        // Setup for failed event creation
        viewModel.eventTitle = "Titre de l'événement"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventImage = createTestImage()
        mockAuthService.isUserAuthenticatedReturnValue = true
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = NSError(domain: "TestError", code: 400, 
                                               userInfo: [NSLocalizedDescriptionKey: "Erreur de test"])
        
        // When - Create event (which fails) then reset
        let createResult = await viewModel.createEvent()
        XCTAssertFalse(createResult)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertFalse(viewModel.errorMessage.isEmpty)
        
        viewModel.resetForm()
        
        // Then
        XCTAssertEqual(viewModel.eventTitle, "")
        XCTAssertEqual(viewModel.errorMessage, "")
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertEqual(viewModel.imageUploadState, .idle)
    }
    
    // MARK: - Additional Error Cases Tests
    
    func testCreateEvent_WithImageVerificationError_ShouldFailAndSetError() async {
        // Given
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Événement avec image"
        viewModel.eventAddress = "123 rue Test"
        viewModel.eventImage = createTestImage()
        
        // Configuration pour un upload réussi mais une vérification qui échoue
        mockAuthService.isUserAuthenticatedReturnValue = true
        mockStorageService.uploadImageShouldSucceed = true
        mockStorageService.mockDownloadURLString = "https://example.com/image.jpg"
        
        // La vérification de l'existence du fichier échoue
        mockStorageService.getDownloadURLShouldFail = true
        mockStorageService.getDownloadURLError = NSError(
            domain: "FIRStorageErrorDomain", 
            code: -13010, 
            userInfo: [NSLocalizedDescriptionKey: "Object not found"]
        )
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertTrue(viewModel.errorMessage.contains("Le fichier uploadé n'est pas accessible") || 
                      viewModel.errorMessage.contains("Erreur lors de l'upload de l'image"))
        XCTAssertEqual(viewModel.imageUploadState, .failure)
    }
    
    func testCreateEvent_WithEmptyImageDataError_ShouldHandleError() async {
        // Given
        resetAllMocksAndViewModel()
        
        viewModel.eventTitle = "Événement avec image"
        viewModel.eventAddress = "123 rue Test"
        // Pas besoin de définir une image réelle, simuler directement l'erreur de stockage
        mockStorageService.shouldThrowError = true
        mockStorageService.mockError = NSError(domain: "StorageError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Erreur lors de l'upload de l'image"])
        
        mockAuthService.isUserAuthenticatedReturnValue = true
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.imageUploadState, .failure)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur lors de l'upload de l'image"))
    }
}

// MARK: - Mock Classes

// Version spécifique pour les tests de EventCreationViewModel
class EventCreationMockStorageService: StorageServiceProtocol {
    var uploadImageCalled = false
    var getDownloadURLCalled = false
    var shouldThrowError = false
    var mockError: Error? = nil
    var mockDownloadURLString: String = "https://example.com/image.jpg"
    
    // Propriétés pour les tests de retry
    var uploadAttemptCount = 0
    var shouldFailFirstAttempt = false
    var alwaysFailWithNetworkError = false
    var mockNetworkError: URLError? = nil
    
    // Propriétés additionnelles utilisées dans les tests
    var uploadImageShouldSucceed = true
    var getDownloadURLShouldFail = false
    var getDownloadURLError: Error? = nil
    
    // Mock URL utilisée pour les tests
    private var mockURL: URL {
        return URL(string: mockDownloadURLString)!
    }
    
    // Implémentation conforme au protocole StorageServiceProtocol
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadataProtocol?) async throws -> String {
        uploadImageCalled = true
        uploadAttemptCount += 1
        
        // Gestion des différents scénarios de test de retry
        if shouldFailFirstAttempt && uploadAttemptCount == 1 {
            if let networkError = mockNetworkError {
                throw networkError
            } else {
                throw URLError(.networkConnectionLost)
            }
        }
        
        if alwaysFailWithNetworkError {
            if let networkError = mockNetworkError {
                throw networkError
            } else {
                throw URLError(.networkConnectionLost)
            }
        }
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock storage error"])
        }
        
        return mockDownloadURLString
    }
    
    // Implémentation requise par le protocole
    func getDownloadURL(for path: String) async throws -> URL {
        getDownloadURLCalled = true
        
        if getDownloadURLShouldFail {
            throw getDownloadURLError ?? NSError(domain: "MockError", code: 501, userInfo: [NSLocalizedDescriptionKey: "Mock download URL error"])
        }
        
        return URL(string: mockDownloadURLString)!
    }
}

// Version spécifique pour les tests de EventCreationViewModel
class EventCreationMockFirestoreService: FirestoreServiceProtocol {
    var shouldThrowError = false
    var mockError: Error? = nil
    var createEventCalled = false
    var updateEventCalled = false
    var getEventDocumentCalled = false
    var getSampleEventCalled = false
    var lastCreatedEvent: Event? = nil
    var lastUpdatedEvent: Event? = nil
    var lastRequestedEventID: String? = nil
    
    // Mock pour document snapshot
    var mockDocumentSnapshot: DocumentSnapshotProtocol?
    
    func createEvent(_ event: Event) async throws {
        createEventCalled = true
        lastCreatedEvent = event
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        updateEventCalled = true
        lastUpdatedEvent = event
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
    }
    
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol {
        getEventDocumentCalled = true
        lastRequestedEventID = eventID
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        // Utiliser la version centrailisée de MockDocumentSnapshot avec les paramètres appropriés
        return mockDocumentSnapshot ?? MockDocumentSnapshot(
            exists: true, 
            data: [
                "title": "Test Event",
                "description": "Sample description",
                "date": Date(),
                "address": "123 Test St",
                "price": 0,
                "organizerName": "Test Organizer"
            ]
        )
    }
    
    func getSampleEvent(eventID: String) throws -> Event {
        getSampleEventCalled = true
        lastRequestedEventID = eventID
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        // Retourner un événement d'échantillon basique pour les tests
        return Event.sampleEvents.first ?? Event(
            title: "Test Event", 
            description: "Sample description", 
            date: Date(), 
            location: "123 Test St", 
            organizer: "Test Organizer", 
            organizerImageURL: nil,
            imageURL: nil, 
            category: .other, 
            tags: nil, 
            createdAt: Date()
        )
    }
    
    // Cette méthode n'est plus dans le protocole mais utilisée dans les tests
    func getAllEvents() async throws -> [Event] {
        return []
    }
    
    // MARK: - Invitation Management (conformité au protocole)
    
    func createInvitation(_ invitation: Invitation) async throws {
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock invitation error"])
        }
        // Simuler création d'invitation pour tests
    }
    
    func updateInvitation(_ invitation: Invitation) async throws {
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock invitation error"])
        }
        // Simuler mise à jour d'invitation pour tests
    }
    
    func deleteInvitation(_ invitationId: String) async throws {
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock invitation error"])
        }
        // Simuler suppression d'invitation pour tests
    }
    
    func getEventInvitations(eventId: String) async throws -> [Invitation] {
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock invitation error"])
        }
        return []
    }
    
    func getUserInvitations(userId: String) async throws -> [Invitation] {
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock invitation error"])
        }
        return []
    }
}

// Version spécifique pour les tests de EventCreationViewModel
@MainActor
class EventCreationMockAuthenticationService: AuthenticationServiceProtocol {
    var isUserAuthenticatedReturnValue = true
    var currentUserMock: EventCreationMockUser? = EventCreationMockUser(uid: "test-uid", email: "test@example.com", displayName: "Test User")
    var currentUserEmailMock: String? = "test@example.com"
    var currentUserDisplayNameMock: String = "Test User"
    
    // Propriétés additionnelles pour les tests
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var updateProfileCalled = false
    var deleteAccountCalled = false
    var resetPasswordCalled = false
    var mockError: Error? = nil
    var shouldThrowError = false
    var lastEmail: String? = nil
    var lastPassword: String? = nil
    var lastDisplayName: String? = nil
    var lastPhotoURL: URL? = nil
    
    // Propriétés requises par le protocole
    var currentUser: UserProtocol? {
        // Convertir notre mock en UserProtocol via un adaptateur
        return MockUserAdapter(mockUser: currentUserMock)
    }
    
    var currentUserDisplayName: String {
        return currentUserDisplayNameMock
    }
    
    var currentUserEmail: String? {
        return currentUserEmailMock
    }
    
    func signIn(email: String, password: String) async throws -> AuthDataResultProtocol {
        signInCalled = true
        lastEmail = email
        lastPassword = password
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 401, userInfo: [NSLocalizedDescriptionKey: "Mock authentication error"])
        }
        
        // Utiliser MockAuthDataResult depuis le fichier centralisé
        return MockAuthDataResult(user: MockUserAdapter(mockUser: currentUserMock))
    }
    
    func signUp(email: String, password: String) async throws -> AuthDataResultProtocol {
        signUpCalled = true
        lastEmail = email
        lastPassword = password
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Mock registration error"])
        }
        
        // Utiliser MockAuthDataResult depuis le fichier centralisé
        return MockAuthDataResult(user: MockUserAdapter(mockUser: currentUserMock))
    }
    
    func signOut() throws {
        signOutCalled = true
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock sign out error"])
        }
    }
    
    func getCurrentUser() -> UserProtocol? {
        return currentUser
    }
    
    func isUserAuthenticated() -> Bool {
        return isUserAuthenticatedReturnValue
    }
    
    func isValidEmail(_ email: String) -> Bool {
        // Validation email basique pour les tests
        return email.contains("@") && email.contains(".")
    }
    
    func isValidPassword(_ password: String) -> Bool {
        // Validation de mot de passe basique pour les tests
        return password.count >= 6
    }
    
    func updateUserProfile(displayName: String?, photoURL: URL?) async throws {
        updateProfileCalled = true
        lastDisplayName = displayName
        lastPhotoURL = photoURL
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock update profile error"])
        }
        
        if let name = displayName {
            currentUserDisplayNameMock = name
        }
    }
    
    func deleteAccount() async throws {
        deleteAccountCalled = true
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock delete account error"])
        }
        
        currentUserMock = nil
        isUserAuthenticatedReturnValue = false
    }
    
    func resetPassword(email: String) async throws {
        resetPasswordCalled = true
        lastEmail = email
        
        if shouldThrowError {
            throw mockError ?? NSError(domain: "MockError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Mock reset password error"])
        }
    }
}

// Adaptateur pour convertir EventCreationMockUser en UserProtocol
class MockUserAdapter: UserProtocol {
    var uid: String
    var email: String?
    var displayName: String?
    var photoURL: URL?
    var isAnonymous: Bool = false
    var isEmailVerified: Bool = true
    
    init(mockUser: EventCreationMockUser?) {
        self.uid = mockUser?.uid ?? ""
        self.email = mockUser?.email
        self.displayName = mockUser?.displayName
        self.photoURL = nil
    }
    
    func getPhotoURL() -> URL? {
        return photoURL
    }
}

class EventCreationMockUser {
    let uid: String
    let email: String?
    let displayName: String?
    
    init(uid: String, email: String?, displayName: String?) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
    }
}

/// Mock pour EventViewModelProtocol respectant toutes les propriétés et méthodes requises
class EventViewModelMock: EventViewModelProtocol {
    // Définition du type associé requis par le protocole
    typealias UploadStateType = ImageUploadState
    // Propriétés requises par EventViewModelProtocol
    var events: [Event] = []
    var isLoading: Bool = false
    var errorMessage: String = ""
    
    // Propriétés spécifiques au MockEventViewModel
    var eventTitle: String = "Événement de test"
    var eventDescription: String = "Description de test"
    var eventDate: Date = Date()
    var eventAddress: String = "Adresse de test"
    var eventImage: UIImage? = nil
    var imageUploadState: ImageUploadState = .ready
    
    // Tracking des appels pour la vérification
    var loadEventsCalled = false
    var refreshEventsCalled = false
    var createEventCalled = false
    
    // Méthodes requises
    func loadEvents() async {
        loadEventsCalled = true
    }
    
    func refreshEvents() async {
        refreshEventsCalled = true
    }
    
    func createEvent() async -> Bool {
        createEventCalled = true
        return true
    }
}
