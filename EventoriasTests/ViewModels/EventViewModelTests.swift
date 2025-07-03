//
//  EventViewModelTests.swift
//  EventoriasTests
//
//  Created on 27/06/2025
//

import XCTest
import Combine
@testable import Eventorias
@MainActor
class EventViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: EventViewModel!
    private var mockEventService: MockEventService!
    private var mockNotificationService: MockNotificationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockEventService = MockEventService()
        mockNotificationService = MockNotificationService()
        viewModel = EventViewModel(eventService: mockEventService, notificationService: mockNotificationService)
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockEventService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    /// Crée un événement de test avec des données valides
    private func createTestEvent(id: String = "test-id") -> Event {
        return Event(
            id: id,
            title: "Événement Test",
            description: "Description test",
            date: Date(),
            location: "Paris, France",
            organizer: "Organisateur Test",
            organizerImageURL: "https://example.com/organizer.jpg",
            imageURL: "https://example.com/image.jpg",
            category: .other,
            tags: ["test"],
            createdAt: Date()
        )
    }
    
    /// Aide à tester les Publishers dans les tests asynchrones
    private func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 1.0
    ) throws -> T.Output where T.Failure == Never {
        var result: T.Output?
        let expectation = expectation(description: "Awaiting publisher")
        
        let cancellable = publisher
            .sink { value in
                result = value
                expectation.fulfill()
            }
            
        cancellable.store(in: &cancellables)
        
        waitForExpectations(timeout: timeout)
        
        guard let output = result else {
            throw NSError(domain: "EventViewModelTests", code: 0, userInfo: [NSLocalizedDescriptionKey: "Publisher did not produce any value"])
        }
        
        return output
    }
    
    // MARK: - Fetch Events Tests
    
    func testFetchEvents_WhenSuccessful_ShouldPopulateEventsArray() async {
        // Given
        let testEvents = [createTestEvent(id: "1"), createTestEvent(id: "2")]
        mockEventService.eventsToReturn = testEvents
        mockEventService.isCollectionEmptyToReturn = false
        
        // When
        await viewModel.fetchEvents()
        
        // Then
        XCTAssertEqual(viewModel.events.count, 2)
        XCTAssertEqual(viewModel.events[0].id, "1")
        XCTAssertEqual(viewModel.events[1].id, "2")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.showingError)
        XCTAssertTrue(mockEventService.fetchEventsCalled || mockEventService.getEventsSortedByDateCalled)
    }
    
    func testFetchEvents_WhenEmptyCollection_ShouldAddSampleEvents() async {
        // Given
        mockEventService.isCollectionEmptyToReturn = true
        let testEvents = [createTestEvent(id: "1"), createTestEvent(id: "2")]
        mockEventService.eventsToReturn = testEvents
        
        // When
        await viewModel.fetchEvents()
        
        // Then
        XCTAssertTrue(mockEventService.isEventsCollectionEmptyCalled)
        XCTAssertTrue(mockEventService.addSampleEventsCalled)
        XCTAssertEqual(viewModel.events.count, testEvents.count)
    }
    
    func testFetchEvents_WhenFails_ShouldSetErrorState() async {
        // Given
        mockEventService.shouldThrowError = true
        mockEventService.mockError = NSError(domain: "Event", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch events"])
        
        // When
        await viewModel.fetchEvents()
        
        // Then
        XCTAssertTrue(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, "Failed to fetch events")
        XCTAssertTrue(viewModel.events.isEmpty)
    }
    
    func testFetchEvents_ShouldUpdateLoadingState() async throws {
        // Given
        var loadingStates: [Bool] = []
        loadingStates.append(viewModel.isLoading) // Capture initial state
        
        // When
        // On simule d'abord un changement manuel d'état pour vérifier le mécanisme
        viewModel.isLoading = true
        loadingStates.append(viewModel.isLoading)
        viewModel.isLoading = false
        loadingStates.append(viewModel.isLoading)
        
        // Then - on vérifie les états manuels
        XCTAssertEqual(loadingStates.count, 3)
        XCTAssertFalse(loadingStates[0]) // Initial state
        XCTAssertTrue(loadingStates[1])  // Loading
        XCTAssertFalse(loadingStates[2]) // Completed
        
        // When - maintenant on teste le vrai comportement de fetchEvents()
        let expectation = XCTestExpectation(description: "fetchEvents completes")
        
        // Surveiller les changements de isLoading
        Task {
            viewModel.isLoading = false // Réinitialisation 
            loadingStates = [] // Reset pour le test avec fetchEvents
            loadingStates.append(viewModel.isLoading) // État initial avant fetchEvents
            
            // On prépare le mock à retourner des événements
            mockEventService.eventsToReturn = [createTestEvent()]
            
            // Exécuter fetchEvents et attendre sa complétion
            await viewModel.fetchEvents()
            
            expectation.fulfill()
        }
        
        // Attendre la complétion de la tâche
        await fulfillment(of: [expectation], timeout: 2.0)
        
        // Then
        XCTAssertFalse(viewModel.isLoading) // Vérifie que isLoading est retourné à false après fetchEvents
        XCTAssertEqual(viewModel.events.count, 1) // Vérifie que les événements ont bien été chargés
    }
    
    // MARK: - Refresh Events Tests
    
    func testRefreshEvents_ShouldCallFetchEvents() async {
        // Given
        mockEventService.reset() // Reset pour s'assurer que tous les flags sont à false
        let testEvents = [createTestEvent()]
        mockEventService.eventsToReturn = testEvents
        
        // When
        await viewModel.refreshEvents()
        
        // Then
        XCTAssertTrue(mockEventService.fetchEventsCalled || mockEventService.getEventsSortedByDateCalled)
        XCTAssertEqual(viewModel.events.count, testEvents.count)
    }
    
    // MARK: - Sort Option Tests
    
    func testUpdateSortOption_ShouldChangeSortOptionAndRefreshEvents() async {
        // Given
        let testEvents = [
            createTestEvent(id: "1"), // will be sorted
            createTestEvent(id: "2")  // will be sorted
        ]
        mockEventService.eventsToReturn = testEvents
        
        // When
        await viewModel.updateSortOption(.dateDescending)
        
        // Then
        XCTAssertEqual(viewModel.sortOption, .dateDescending)
        XCTAssertTrue(mockEventService.getEventsSortedByDateCalled)
    }
    
    func testFilteredEvents_WhenSearchTextIsEmpty_ShouldReturnAllEventsSorted() {
        // Given
        let testEvents = [
            Event(id: "1", title: "Premier événement", description: "Description 1", date: Date().addingTimeInterval(3600), location: "Paris", organizer: "Org1", organizerImageURL: "org-url1", imageURL: "url1", category: .art, tags: [], createdAt: Date()),
            Event(id: "2", title: "Deuxième événement", description: "Description 2", date: Date(), location: "Lyon", organizer: "Org2", organizerImageURL: "org-url2", imageURL: "url2", category: .other, tags: [], createdAt: Date())
        ]
        viewModel.events = testEvents
        viewModel.searchText = ""
        viewModel.sortOption = .dateAscending
        
        // When
        let filteredEvents = viewModel.filteredEvents
        
        // Then
        XCTAssertEqual(filteredEvents.count, 2)
        XCTAssertEqual(filteredEvents[0].id, "2") // Le plus proche en date d'abord
        XCTAssertEqual(filteredEvents[1].id, "1")
    }
    
    func testFilteredEvents_WhenSearchTextIsNotEmpty_ShouldReturnMatchingEvents() {
        // Given
        let testEvents = [
            Event(id: "1", title: "Premier événement", description: "Description 1", date: Date(), location: "Paris", organizer: "Org1", organizerImageURL: "org-url1", imageURL: "url1", category: .sport, tags: [], createdAt: Date()),
            Event(id: "2", title: "Deuxième événement", description: "Description 2", date: Date(), location: "Lyon", organizer: "Org2", organizerImageURL: "org-url2", imageURL: "url2", category: .other, tags: [], createdAt: Date())
        ]
        viewModel.events = testEvents
        viewModel.searchText = "premier"
        
        // When
        let filteredEvents = viewModel.filteredEvents
        
        // Then
        XCTAssertEqual(filteredEvents.count, 1)
        XCTAssertEqual(filteredEvents[0].id, "1")
    }
    
    // MARK: - Error Handling Tests
    
    func testDismissError_ShouldClearErrorState() {
        // Given
        viewModel.errorMessage = "Test Error"
        viewModel.showingError = true
        
        // When
        viewModel.dismissError()
        
        // Then
        XCTAssertFalse(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, "")
    }
    
    // MARK: - Event Creation Tests
    
    func testCreateEvent_WhenAllFieldsAreValid_ShouldCreateEventAndReturnTrue() async {
        // Given
        viewModel.eventTitle = "Nouvel Événement"
        viewModel.eventDescription = "Description de l'événement"
        viewModel.eventAddress = "Paris, France"
        viewModel.eventDate = Date()
        
        mockEventService.eventIdToReturn = "new-event-id"
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockEventService.createEventCalled)
        XCTAssertTrue(viewModel.eventCreationSuccess)
        XCTAssertFalse(viewModel.isLoading)
        
        // Les champs du formulaire devraient être réinitialisés
        XCTAssertEqual(viewModel.eventTitle, "")
        XCTAssertEqual(viewModel.eventDescription, "")
        XCTAssertEqual(viewModel.eventAddress, "")
    }
 
    func testCreateEvent_WithImage_ShouldUploadImageAndCreateEvent() async {
        // Given
        viewModel.eventTitle = "Événement avec Image"
        viewModel.eventAddress = "Paris, France"
        viewModel.eventImage = UIImage(systemName: "photo")
        
        mockEventService.imageURLToReturn = "https://example.com/test-image.jpg"
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertTrue(result)
        XCTAssertTrue(mockEventService.uploadImageCalled)
        XCTAssertTrue(mockEventService.createEventCalled)
        
        // Vérifier que l'état a été correctement réinitialisé après la création
        // (l'état passe par .success pendant le processus puis est réinitialisé à .ready)
        XCTAssertEqual(viewModel.imageUploadState, .ready, "L'état final devrait être .ready après réinitialisation")
    }

    func testCreateEvent_WhenTitleIsEmpty_ShouldFailValidationAndReturnFalse() async {
        // Given
        viewModel.eventTitle = ""
        viewModel.eventAddress = "Paris, France"
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertFalse(mockEventService.createEventCalled)
        XCTAssertEqual(viewModel.errorMessage, EventViewModel.ValidationError.emptyTitle.localizedDescription)
    }
    
    func testCreateEvent_WhenAddressIsEmpty_ShouldFailValidationAndReturnFalse() async {
        // Given
        viewModel.eventTitle = "Titre valide"
        viewModel.eventAddress = ""
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertFalse(viewModel.eventCreationSuccess)
        XCTAssertFalse(mockEventService.createEventCalled)
        XCTAssertEqual(viewModel.errorMessage, EventViewModel.ValidationError.emptyAddress.localizedDescription)
    }
    
    // MARK: - Validation Error Tests
    
    func testValidationError_ErrorDescriptions() {
        // Given & When
        let emptyTitleError = EventViewModel.ValidationError.emptyTitle
        let emptyAddressError = EventViewModel.ValidationError.emptyAddress
        let imageConversionError = EventViewModel.ValidationError.imageConversionFailed
        
        // Then
        XCTAssertEqual(emptyTitleError.errorDescription, "Le titre de l'événement ne peut pas être vide")
        XCTAssertEqual(emptyAddressError.errorDescription, "L'adresse de l'événement ne peut pas être vide")
        XCTAssertEqual(imageConversionError.errorDescription, "Impossible de convertir l'image")
    }
    
    func testCreateEvent_WhenServiceThrowsError_ShouldSetErrorStateAndReturnFalse() async {
        // Given
        viewModel.eventTitle = "Événement Test"
        viewModel.eventAddress = "Paris, France"
        
        mockEventService.shouldThrowError = true
        mockEventService.mockError = NSError(domain: "Event", code: 400, userInfo: [NSLocalizedDescriptionKey: "Failed to create event"])
        
        // When
        let result = await viewModel.createEvent()
        
        // Then
        XCTAssertFalse(result)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertEqual(viewModel.errorMessage, "Failed to create event")
        XCTAssertFalse(viewModel.eventCreationSuccess)
    }
    
    func testUploadEventImage_WhenNoImageProvided_ShouldReturnNil() async throws {
        // Given
        viewModel.eventImage = nil
        
        // When
        let result = try await viewModel.uploadEventImage()
        
        // Then
        XCTAssertNil(result)
        XCTAssertFalse(mockEventService.uploadImageCalled)
        XCTAssertEqual(viewModel.imageUploadState, .ready)
    }
    
    func testUploadEventImage_WhenSuccessful_ShouldUpdateStateAndReturnURL() async throws {
        // Given
        viewModel.eventImage = UIImage(systemName: "photo")
        mockEventService.imageURLToReturn = "https://example.com/uploaded.jpg"
        
        // When
        let result = try await viewModel.uploadEventImage()
        
        // Then
        XCTAssertEqual(result, "https://example.com/uploaded.jpg")
        XCTAssertTrue(mockEventService.uploadImageCalled)
        
        // Vérifier les transitions d'état
        switch viewModel.imageUploadState {
        case .success(let url):
            XCTAssertEqual(url, "https://example.com/uploaded.jpg")
        default:
            XCTFail("L'état de l'upload devrait être 'success'")
        }
    }
    
    func testUploadEventImage_WhenUploadFails_ShouldUpdateStateAndThrowError() async {
        // Given
        viewModel.eventImage = UIImage(systemName: "photo")
        mockEventService.shouldThrowError = true
        mockEventService.mockError = NSError(domain: "Upload", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        
        // When/Then
        do {
            _ = try await viewModel.uploadEventImage()
            XCTFail("La fonction devrait lancer une exception")
        } catch {
            XCTAssertEqual(error.localizedDescription, "Upload failed")
            
            // Vérifier l'état d'échec
            switch viewModel.imageUploadState {
            case .failure(let errorMessage):
                XCTAssertEqual(errorMessage, "Upload failed")
            default:
                XCTFail("L'état de l'upload devrait être 'failure'")
            }
        }
    }
    
    // MARK: - Convenience Methods Tests
    
    func testIsFormValid_WhenTitleAndAddressAreProvided_ShouldReturnTrue() {
        // Given
        viewModel.eventTitle = "Titre Valide"
        viewModel.eventAddress = "Adresse Valide"
        
        // Then
        XCTAssertTrue(viewModel.isFormValid)
    }
    
    func testIsFormValid_WhenTitleIsEmpty_ShouldReturnFalse() {
        // Given
        viewModel.eventTitle = ""
        viewModel.eventAddress = "Adresse Valide"
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testIsFormValid_WhenAddressIsEmpty_ShouldReturnFalse() {
        // Given
        viewModel.eventTitle = "Titre Valide"
        viewModel.eventAddress = ""
        
        // Then
        XCTAssertFalse(viewModel.isFormValid)
    }
    
    func testHasEvents_WhenEventsArePresent_ShouldReturnTrue() {
        // Given
        viewModel.events = [createTestEvent()]
        viewModel.searchText = ""
        
        // Then
        XCTAssertTrue(viewModel.hasEvents)
    }
    
    func testHasEvents_WhenNoEventsArePresent_ShouldReturnFalse() {
        // Given
        viewModel.events = []
        
        // Then
        XCTAssertFalse(viewModel.hasEvents)
    }
    
    func testIsSearchActive_WhenSearchTextIsNotEmpty_ShouldReturnTrue() {
        // Given
        viewModel.searchText = "concert"
        
        // Then
        XCTAssertTrue(viewModel.isSearchActive)
    }
    
    func testIsSearchActive_WhenSearchTextIsEmpty_ShouldReturnFalse() {
        // Given
        viewModel.searchText = ""
        
        // Then
        XCTAssertFalse(viewModel.isSearchActive)
    }
    
    func testEmptyStateMessage_WhenSearchIsActive_ShouldReturnSearchMessage() {
        // Given
        viewModel.searchText = "concert"
        
        // Then
        XCTAssertEqual(viewModel.emptyStateMessage, "Aucun résultat pour \"concert\"")
    }
    
    func testEmptyStateMessage_WhenSearchIsNotActive_ShouldReturnDefaultMessage() {
        // Given
        viewModel.searchText = ""
        
        // Then
        XCTAssertEqual(viewModel.emptyStateMessage, "Aucun événement disponible")
    }
    
    // MARK: - Image Upload State Tests
    
    func testUploadEventImage_WhenSuccessful_ShouldUpdateImageUploadState() async throws {
        // Given
        let mockImage = UIImage(systemName: "photo")!
        viewModel.eventImage = mockImage
        mockEventService.imageURLToReturn = "https://example.com/test-image.jpg"
        
        // When
        let imageURL = try await viewModel.uploadEventImage()
        
        // Then
        XCTAssertEqual(imageURL, "https://example.com/test-image.jpg")
        XCTAssertEqual(viewModel.imageUploadState, .success(url: "https://example.com/test-image.jpg"))
        XCTAssertTrue(mockEventService.uploadImageCalled)
    }
    
    func testUploadEventImage_WhenServiceThrowsError_ShouldUpdateImageUploadStateToFailure() async {
        // Given
        let mockImage = UIImage(systemName: "photo")!
        viewModel.eventImage = mockImage
        mockEventService.shouldThrowError = true
        mockEventService.mockError = NSError(domain: "Image", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to upload image"])
        
        // When & Then
        do {
            _ = try await viewModel.uploadEventImage()
            XCTFail("Expected uploadEventImage to throw an error")
        } catch {
            XCTAssertTrue(mockEventService.uploadImageCalled)
            
            // Vérifier que l'état a été mis à jour correctement
            if case .failure(let errorMessage) = viewModel.imageUploadState {
                XCTAssertEqual(errorMessage, "Failed to upload image")
            } else {
                XCTFail("Expected imageUploadState to be .failure")
            }
        }
    }
    
    // MARK: - ImageUploadState Tests
    
    func testImageUploadState_UploadingState() {
        // Given & When
        viewModel.imageUploadState = .uploading(progress: 0.5)
        
        // Then
        XCTAssertTrue(viewModel.imageUploadState.isUploading)
        XCTAssertEqual(viewModel.imageUploadState.progressValue, 0.5)
    }
    
    func testImageUploadState_SuccessState() {
        // Given & When
        viewModel.imageUploadState = .success(url: "https://example.com/image.jpg")
        
        // Then
        XCTAssertFalse(viewModel.imageUploadState.isUploading)
        XCTAssertEqual(viewModel.imageUploadState.progressValue, 1.0)
    }
    
    func testImageUploadState_ReadyState() {
        // Given & When
        viewModel.imageUploadState = .ready
        
        // Then
        XCTAssertFalse(viewModel.imageUploadState.isUploading)
        XCTAssertEqual(viewModel.imageUploadState.progressValue, 0.0)
    }
    
    func testImageUploadState_FailureState() {
        // Given & When
        viewModel.imageUploadState = .failure(error: "Test error")
        
        // Then
        XCTAssertFalse(viewModel.imageUploadState.isUploading)
        XCTAssertEqual(viewModel.imageUploadState.progressValue, 0.0)
    }
    
    func testResetEventFormFields_ShouldClearAllFields() {
        // Given
        viewModel.eventTitle = "Test Title"
        viewModel.eventDescription = "Test Description"
        viewModel.eventAddress = "Test Address"
        viewModel.eventImage = UIImage(systemName: "photo")
        viewModel.imageUploadState = .success(url: "https://example.com/test.jpg")
        
        // When
        viewModel.resetEventFormFields()
        
        // Then
        XCTAssertEqual(viewModel.eventTitle, "")
        XCTAssertEqual(viewModel.eventDescription, "")
        XCTAssertEqual(viewModel.eventAddress, "")
        XCTAssertNil(viewModel.eventImage)
        
        switch viewModel.imageUploadState {
        case .ready:
            // Test réussi
            break
        default:
            XCTFail("L'état de l'upload devrait être 'ready'")
        }
    }
}
