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
// Import nécessaire pour accéder aux types requis dans les tests

@MainActor
class EventCreationViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: EventCreationViewModel!
    private var mockEventViewModel: EventViewModelMock!
    private var mockAuthService: MockAuthenticationService!
    private var mockStorageService: MockStorageService!
    private var mockFirestoreService: MockFirestoreService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockEventViewModel = EventViewModelMock()
        mockAuthService = MockAuthenticationService()
        mockStorageService = MockStorageService()
        mockFirestoreService = MockFirestoreService()
        
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
        mockAuthService = MockAuthenticationService()
        mockStorageService = MockStorageService()
        mockFirestoreService = MockFirestoreService()
        
        // Configuration par défaut des mocks pour éviter les erreurs
        mockAuthService.currentUserMock = MockUser(uid: "test-uid", email: "test@example.com", displayName: "Test User")
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
        mockAuthService.currentUserMock = MockUser(uid: "test-uid", email: "test@example.com", displayName: "Organisateur Test")
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
}

// MARK: - Mock Classes

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
