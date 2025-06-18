//
// EventDetailsViewModelTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
import CoreLocation
import Firebase
@testable import Eventorias

@MainActor
final class EventDetailsViewModelTests: XCTestCase {
    
    // System under test
    var sut: EventDetailsViewModel!
    
    // Mock dependencies
    var mockFirestoreService: MockEventFirestoreService!
    var mockGeocodingService: MockGeocodingService!
    var mockMapNetworkService: MockMapNetworkService!
    var mockConfigurationService: MockConfigurationService!
    
    override func setUp() {
        super.setUp()
        
        // Initialize mocks
        mockFirestoreService = MockEventFirestoreService()
        mockGeocodingService = MockGeocodingService()
        mockMapNetworkService = MockMapNetworkService()
        mockConfigurationService = MockConfigurationService()
        
        // Initialize SUT with mocks
        sut = EventDetailsViewModel(
            firestoreService: mockFirestoreService,
            geocodingService: mockGeocodingService,
            mapNetworkService: mockMapNetworkService,
            configurationService: mockConfigurationService
        )
    }
    
    override func tearDown() {
        sut = nil
        mockFirestoreService = nil
        mockGeocodingService = nil
        mockMapNetworkService = nil
        mockConfigurationService = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createSampleEvent() -> Event {
        return Event(
            id: "test-event-id",
            title: "Test Event",
            description: "This is a test event description",
            date: Date(),
            location: "1 Infinite Loop, Cupertino, CA",
            organizer: "test-user-id",
            organizerImageURL: nil,
            imageURL: "https://example.com/image.jpg",
            category: "test",
            tags: [],
            createdAt: Date()
        )
    }
    
    private func setupMockFirestoreForSuccess() {
        // Create a mock DocumentSnapshot with an event
        let sampleEvent = createSampleEvent()
        // Set up the mock to return the sample event
        mockFirestoreService.eventToReturn = sampleEvent
    }
    
    private func setupMockGeocodingForSuccess() {
        // Set mock coordinates directly instead of using placemarks
        mockGeocodingService.mockCoordinates = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    }
    
    // MARK: - Tests
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        // Test initialization with default values
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNil(sut.event)
        XCTAssertNil(sut.coordinates)
        XCTAssertNil(sut.mapImageURL)
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertFalse(sut.showingError)
    }
    
    // MARK: - Loading Event Tests
    
    func testLoadEvent_WithEmptyId() async {
        // Arrange - Empty ID
        let emptyId = ""
        
        // Act
        await sut.loadEvent(eventID: emptyId)
        
        // Assert
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "ID d'événement invalide")
        XCTAssertNil(sut.event)
        // Verify that the service was not called with empty ID
        XCTAssertFalse(mockFirestoreService.getEventDocumentCalled)
    }
    
    func testLoadEvent_FirestoreSuccess() async {
        // Arrange
        let eventId = "test-event-id"
        let sampleEvent = createSampleEvent()
        
        // Create a mock event and set it up
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        
        // Act
        await sut.loadEvent(eventID: eventId)
        
        // Assert
        XCTAssertFalse(sut.showingError)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.event)
        XCTAssertEqual(sut.event?.id, sampleEvent.id)
        XCTAssertEqual(sut.event?.title, sampleEvent.title)
        
        // Verify the service was called with the correct ID
        XCTAssertTrue(mockFirestoreService.getEventDocumentCalled)
        XCTAssertEqual(mockFirestoreService.lastEventIDRequested, eventId)
    }
    
    func testLoadEvent_FirestoreFailure() async {
        // Arrange
        let eventId = "test-event-id"
        
        // Set up the mock to throw an error when getEventDocument is called
        mockFirestoreService.errorToThrow = EventDetailsError.networkError
        
        // Act
        await sut.loadEvent(eventID: eventId)
        
        // Assert
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.isLoading)
        XCTAssertTrue(sut.errorMessage.contains("Impossible de charger"))
        XCTAssertNil(sut.event)
        
        // Verify the service was called
        XCTAssertTrue(mockFirestoreService.getEventDocumentCalled)
    }
    
    func testLoadEvent_FirestoreNotFound_SampleEventSuccess() async {
        // Arrange
        let eventId = "test-event-id"
        let sampleEvent = createSampleEvent()
        
        // Setup mock document not found but sample event available
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: false)
        mockFirestoreService.eventToReturn = sampleEvent
        
        // Act
        await sut.loadEvent(eventID: eventId)
        
        // Assert
        XCTAssertFalse(sut.showingError)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNotNil(sut.event)
        XCTAssertEqual(sut.event?.id, sampleEvent.id)
        
        // Verify both services were called
        XCTAssertTrue(mockFirestoreService.getEventDocumentCalled)
        XCTAssertTrue(mockFirestoreService.getSampleEventCalled)
    }
    
    // MARK: - Geocoding Tests
    
    func testGeocodeEventLocation_WithEmptyAddress() async {
        // Arrange - No event defined
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNil(sut.coordinates)
        XCTAssertNil(sut.mapImageURL)
        
        // Verify the geocoding service was not called
        XCTAssertFalse(mockGeocodingService.geocodeAddressCalled)
    }
    
    func testGeocodeEventLocation_Success() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        let latitude = 37.7749
        let longitude = -122.4194
        
        // Set up the view model with an event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up geocoding mock to return coordinates
        mockGeocodingService.mockCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNotNil(sut.coordinates)
        
        // ✅ CORRECTION: Déballage sécurisé des coordonnées
        if let coordinates = sut.coordinates {
            XCTAssertEqual(coordinates.latitude, latitude, accuracy: 0.0001)
            XCTAssertEqual(coordinates.longitude, longitude, accuracy: 0.0001)
        } else {
            XCTFail("Les coordonnées ne devraient pas être nil après un géocodage réussi")
        }
        
        // Verify the geocoding service was called with the correct address
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
        XCTAssertEqual(mockGeocodingService.lastAddressGeocoded, sampleEvent.location)
    }

    
    func testGeocodeEventLocation_EmptyPlacemarks() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        
        // Set up the view model with an event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up geocoding mock to return empty placemark array
        mockGeocodingService.shouldReturnEmptyPlacemarks = true
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNil(sut.coordinates)
        XCTAssertNil(sut.mapImageURL)
        XCTAssertTrue(sut.errorMessage.contains("Impossible de localiser"))
        
        // Verify the geocoding service was called
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
    }
    
    func testGeocodeEventLocation_Error() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        
        // Set up the view model with an event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up geocoding mock to throw an error
        mockGeocodingService.shouldThrowError = true
        mockGeocodingService.errorToThrow = EventDetailsError.geocodingError
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNil(sut.coordinates)
        XCTAssertNil(sut.mapImageURL)
        XCTAssertTrue(sut.errorMessage.contains("Impossible de géocoder"))
        
        // Verify the geocoding service was called
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
    }
    
    // MARK: - Formatting Tests
    
    func testFormattedEventTime_WithNoEvent() {
        // Arrange - No event defined
        
        // Act
        let timeString = sut.formattedEventTime()
        
        // Assert
        XCTAssertEqual(timeString, "")
    }
    
    func testFormattedEventTime_WithEvent() async {
        // Arrange
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let specificDate = dateFormatter.date(from: "2025-06-15 14:30:00")!
        
        let sampleEvent = Event(
            id: "test-event-id",
            title: "Test Event",
            description: "This is a test event description",
            date: specificDate,
            location: "1 Infinite Loop, Cupertino, CA",
            organizer: "test-user-id",
            organizerImageURL: nil,
            imageURL: "https://example.com/image.jpg",
            category: "test",
            tags: [],
            createdAt: Date()
        )
        
        // Set up the view model with the event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Act
        let timeString = sut.formattedEventTime()
        
        // Assert
        XCTAssertEqual(timeString, "14:30")
    }
    
    func testFormattedEventDay_WithNoEvent() {
        // Arrange - No event defined
        
        // Act
        let dayString = sut.formattedEventDay()
        
        // Assert
        XCTAssertEqual(dayString, "")
    }
    
    func testFormattedEventDay_WithEvent() async {
        // Arrange
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let specificDate = dateFormatter.date(from: "2025-06-15 14:30:00")!
        
        let sampleEvent = Event(
            id: "test-event-id",
            title: "Test Event",
            description: "This is a test event description",
            date: specificDate,
            location: "1 Infinite Loop, Cupertino, CA",
            organizer: "test-user-id",
            organizerImageURL: nil,
            imageURL: "https://example.com/image.jpg",
            category: "test",
            tags: [],
            createdAt: Date()
        )
        
        // Set up the view model with the event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Act
        let dayString = sut.formattedEventDay()
        
        // ✅ CORRECTION: Vérifier seulement le format "d" (jour uniquement)
        XCTAssertEqual(dayString, "15")
    }
    
    func testFormattedEventMonth_WithEvent() async {
        // ✅ CORRECTION: Nouveau test pour le mois
        // Arrange
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let specificDate = dateFormatter.date(from: "2025-06-15 14:30:00")!
        
        let sampleEvent = Event(
            id: "test-event-id",
            title: "Test Event",
            description: "This is a test event description",
            date: specificDate,
            location: "1 Infinite Loop, Cupertino, CA",
            organizer: "test-user-id",
            organizerImageURL: nil,
            imageURL: "https://example.com/image.jpg",
            category: "test",
            tags: [],
            createdAt: Date()
        )
        
        // Set up the view model with the event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Act
        let monthString = sut.formattedEventMonth()
        
        // Assert
        XCTAssertTrue(monthString.lowercased().contains("jun"))
    }
    
    // MARK: - API Key Configuration Tests
    
    func testIsMapAPIKeyConfigured_WithValidKey() {
        // ✅ CORRECTION: Utiliser une clé API de plus de 20 caractères
        mockConfigurationService.mockGoogleMapsAPIKey = "valid-api-key-with-sufficient-length-for-testing"
        
        // Act
        let isConfigured = sut.isMapAPIKeyConfigured
        
        // Assert
        XCTAssertTrue(isConfigured)
        XCTAssertTrue(mockConfigurationService.getGoogleMapsAPIKeyCalled)
    }
    
    func testIsMapAPIKeyConfigured_WithEmptyKey() {
        // Arrange
        mockConfigurationService.mockGoogleMapsAPIKey = ""
        
        // Act
        let isConfigured = sut.isMapAPIKeyConfigured
        
        // Assert
        XCTAssertFalse(isConfigured)
        XCTAssertTrue(mockConfigurationService.getGoogleMapsAPIKeyCalled)
    }
    
    func testIsMapAPIKeyConfigured_WithPlaceholderKey() {
        // Arrange
        mockConfigurationService.mockGoogleMapsAPIKey = "YOUR_API_KEY"
        
        // Act
        let isConfigured = sut.isMapAPIKeyConfigured
        
        // Assert
        XCTAssertFalse(isConfigured)
        XCTAssertTrue(mockConfigurationService.getGoogleMapsAPIKeyCalled)
    }
    
    func testIsMapAPIKeyConfigured_WithShortKey() {
        // ✅ CORRECTION: Nouveau test pour clé trop courte
        mockConfigurationService.mockGoogleMapsAPIKey = "short-key"
        
        // Act
        let isConfigured = sut.isMapAPIKeyConfigured
        
        // Assert
        XCTAssertFalse(isConfigured)
        XCTAssertTrue(mockConfigurationService.getGoogleMapsAPIKeyCalled)
    }
    
    // MARK: - Map Image URL Generation Tests
    
    func testGenerateMapImageURL_WithNoCoordinates() async {
        // Arrange - No coordinates defined
        let sampleEvent = createSampleEvent()
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Make sure coordinates are nil
        sut.coordinates = nil
        
        // Set a valid API key in the mock configuration service
        mockConfigurationService.mockGoogleMapsAPIKey = "valid-api-key-with-sufficient-length-for-testing"
        
        // Act - we call geocodeEventLocation which internally calls generateMapImageURL when successful
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertNil(sut.mapImageURL)
    }
    
    func testGenerateMapImageURL_WithCoordinates() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        let latitude = 37.7749
        let longitude = -122.4194
        
        // Set up the view model with an event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up geocoding mock to return coordinates
        mockGeocodingService.mockCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // ✅ CORRECTION: Utiliser une clé API valide
        mockConfigurationService.mockGoogleMapsAPIKey = "valid-api-key-with-sufficient-length-for-testing"
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertNotNil(sut.mapImageURL)
        XCTAssertTrue(sut.mapImageURL?.absoluteString.contains("maps.googleapis.com") ?? false)
        XCTAssertTrue(sut.mapImageURL?.absoluteString.contains("valid-api-key-with-sufficient-length-for-testing") ?? false)
        XCTAssertTrue(sut.mapImageURL?.absoluteString.contains("37.774900") ?? false)
        XCTAssertTrue(sut.mapImageURL?.absoluteString.contains("-122.419400") ?? false)
        
        // Verify the right services were called
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
        XCTAssertTrue(mockConfigurationService.getGoogleMapsAPIKeyCalled)
    }
    
    // MARK: - Map Error Handling Tests
    
    func testMapValidation_Success() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up coordinates and map URL
        let latitude = 37.7749
        let longitude = -122.4194
        mockGeocodingService.mockCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mockConfigurationService.mockGoogleMapsAPIKey = "valid-api-key-with-sufficient-length-for-testing"
        
        // Configure mock network service for success
        mockMapNetworkService.mockSuccess = true
        
        // Act - Geocode will trigger map validation
        await sut.geocodeEventLocation()
        
        // ✅ CORRECTION: Attendre la validation asynchrone
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 secondes
        
        // Assert
        XCTAssertNotNil(sut.mapImageURL)
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertFalse(sut.showingError)
        XCTAssertTrue(mockMapNetworkService.validateURLCalled)
    }
    
    func testMapValidation_NetworkError() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up coordinates and map URL
        let latitude = 37.7749
        let longitude = -122.4194
        mockGeocodingService.mockCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mockConfigurationService.mockGoogleMapsAPIKey = "valid-api-key-with-sufficient-length-for-testing"
        
        // Configure mock network service to throw an error
        mockMapNetworkService.shouldThrowError = true
        mockMapNetworkService.errorToThrow = MapError.networkError("Test network error")
        
        // Act - Geocode will trigger map validation
        await sut.geocodeEventLocation()
        
        // ✅ CORRECTION: Attendre la validation asynchrone
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 secondes
        
        // Assert
        XCTAssertNotNil(sut.mapImageURL) // URL should still be set
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertTrue(sut.errorMessage.contains("Test network error"))
        XCTAssertTrue(sut.showingError)
        XCTAssertTrue(mockMapNetworkService.validateURLCalled)
    }
    
    func testMapValidation_InvalidImageData() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Set up coordinates and map URL
        let latitude = 37.7749
        let longitude = -122.4194
        mockGeocodingService.mockCoordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        mockConfigurationService.mockGoogleMapsAPIKey = "valid-api-key-with-sufficient-length-for-testing"
        
        // Configure mock network service to throw an invalid data error
        mockMapNetworkService.shouldThrowError = true
        mockMapNetworkService.errorToThrow = MapError.invalidImageData
        
        // Act - Geocode will trigger map validation
        await sut.geocodeEventLocation()
        
        // ✅ CORRECTION: Attendre la validation asynchrone
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 secondes
        
        // Assert
        XCTAssertNil(sut.mapImageURL) // URL should be reset to nil on invalid data
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertTrue(sut.showingError)
        XCTAssertTrue(mockMapNetworkService.validateURLCalled)
    }
    
    func testCancelTasks() {
        // Arrange - Just need to call the method
        
        // Act
        sut.cancelTasks()
        
        // Assert
        XCTAssertTrue(mockGeocodingService.geocodingCancelled)
    }
    
    // MARK: - Tests supplémentaires pour une meilleure couverture
    
    func testFormattedEventDate_WithEvent() async {
        // Arrange
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let specificDate = dateFormatter.date(from: "2025-06-15 14:30:00")!
        
        let sampleEvent = Event(
            id: "test-event-id",
            title: "Test Event",
            description: "This is a test event description",
            date: specificDate,
            location: "1 Infinite Loop, Cupertino, CA",
            organizer: "test-user-id",
            organizerImageURL: nil,
            imageURL: "https://example.com/image.jpg",
            category: "test",
            tags: [],
            createdAt: Date()
        )
        
        // Set up the view model with the event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // Act
        let dateString = sut.formattedEventDate()
        
        // Assert
        XCTAssertFalse(dateString.isEmpty)
        XCTAssertTrue(dateString.contains("2025"))
    }
    
    func testGeocodeEventLocation_WithExistingCoordinates() async {
        // Arrange
        let sampleEvent = createSampleEvent()
        let latitude = 37.7749
        let longitude = -122.4194
        
        // Set up the view model with an event
        mockFirestoreService.eventToReturn = sampleEvent
        mockFirestoreService.mockDocumentSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: sampleEvent)
        await sut.loadEvent(eventID: sampleEvent.id ?? "test-event-id")
        
        // ✅ Pre-define coordinates before geocoding
        sut.coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        // Reset the geocodeAddressCalled flag after loadEvent which might have triggered geocoding
        mockGeocodingService.geocodeAddressCalled = false
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertNotNil(sut.coordinates)
        
        // Verify coordinates are preserved with the original values
        if let coordinates = sut.coordinates {
            XCTAssertEqual(coordinates.latitude, latitude, accuracy: 0.0001)
            XCTAssertEqual(coordinates.longitude, longitude, accuracy: 0.0001)
        } else {
            XCTFail("Coordinates should not be nil")
        }
        
        // Verify that geocodeAddress was NOT called (should use existing coordinates)
        XCTAssertFalse(mockGeocodingService.geocodeAddressCalled)
    }

}
