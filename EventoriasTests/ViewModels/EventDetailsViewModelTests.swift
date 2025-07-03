
// EventDetailsViewModelTests.swift
// EventoriasTests
//
// Created on 24/06/2025
//

import XCTest
import Combine
import CoreLocation
import MapKit
@testable import Eventorias

// Désambigüïsation explicite du mock
typealias TestFirestoreService = MockFirestoreService

@MainActor
class EventDetailsViewModelTests: XCTestCase {
    
    // MARK: - Properties
    
    private var viewModel: EventDetailsViewModel!
    // Utilisation de l'alias pour éviter l'ambiguïté
    private var mockFirestoreService: TestFirestoreService!
    private var mockGeocodingService: MockGeocodingService!
    private var mockMapNetworkService: MockMapNetworkService!
    private var mockConfigurationService: MockConfigurationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        
        // Utilisation de l'alias TestFirestoreService
        mockFirestoreService = TestFirestoreService()
        mockGeocodingService = MockGeocodingService()
        mockMapNetworkService = MockMapNetworkService()
        mockConfigurationService = MockConfigurationService()
        
        // **Configuration complète pour éviter les erreurs**
        mockConfigurationService.googleMapsAPIKey = "test-api-key-minimum-20-characters"
        
        // **Configuration par défaut du géocodage**
        let defaultPlacemark = createMockPlacemark(latitude: 48.8566, longitude: 2.3522)
        mockGeocodingService.mockPlacemarks = [defaultPlacemark]
        mockGeocodingService.shouldThrowError = false
        
        // **Créer le ViewModel en mode test SANS géocodage automatique**
        viewModel = EventDetailsViewModel(
            firestoreService: mockFirestoreService,
            geocodingService: mockGeocodingService,
            mapNetworkService: mockMapNetworkService,
            configurationService: mockConfigurationService,
            isTestMode: true,
            shouldAutoGeocode: false // ← Désactiver par défaut
        )
        
        cancellables = []
    }
    
    override func tearDown() {
        viewModel = nil
        mockFirestoreService = nil
        mockGeocodingService = nil
        mockMapNetworkService = nil
        mockConfigurationService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockEvent(id: String = "test-event-id") -> Event {
        return Event(
            id: id,
            title: "Événement de test",
            description: "Description de l'événement de test",
            date: Date(),
            location: "123 Rue de Test, Paris",
            organizer: "Organisateur Test",
            organizerImageURL: "https://example.com/organizer.jpg",
            imageURL: "https://example.com/image.jpg",
            category: "Test",
            tags: ["test", "unitaire"],
            createdAt: Date()
        )
    }
    
    private func createMockDocumentSnapshot(exists: Bool, event: Event? = nil, documentID: String? = nil) -> MockDocumentSnapshot {
        if exists, let event = event {
            // Utiliser l'ID explicitement fourni ou l'ID de l'événement
            let eventID = documentID ?? event.id ?? "test-id"
            
            // Créer manuellement le dictionnaire de données au lieu d'utiliser l'encodage JSON
            // pour éviter le problème avec DocumentID
            var dict: [String: Any] = [
                "id": eventID,
                "title": event.title,
                "description": event.description,
                "date": event.date.timeIntervalSince1970, // Convertir la date en timestamp
                "location": event.location,
                "organizer": event.organizer
            ]
            
            // Ajouter les champs optionnels s'ils existent
            if let organizerImageURL = event.organizerImageURL {
                dict["organizerImageURL"] = organizerImageURL
            }
            if let imageURL = event.imageURL {
                dict["imageURL"] = imageURL
            }
            // category n'est pas optionnel, pas besoin de if let
            dict["category"] = event.category
            if let tags = event.tags {
                dict["tags"] = tags
            }
            // createdAt n'est pas optionnel, pas besoin de if let
            dict["createdAt"] = event.createdAt.timeIntervalSince1970 // Convertir la date en timestamp
            
            print("🔵 Création d'un MockDocumentSnapshot avec ID: \(eventID) et données: \(dict)")
            return MockDocumentSnapshot(exists: true, data: dict, id: eventID)
        }
        // Si le document n'existe pas ou pas d'événement fourni
        return MockDocumentSnapshot(exists: false, data: [:])
    }
    
    private func createMockPlacemark(latitude: Double, longitude: Double) -> MockPlacemark {
        let location = CLLocation(latitude: latitude, longitude: longitude)
        return MockPlacemark(
            name: "Test Location",
            thoroughfare: "123 Test Street",
            locality: "Test City",
            country: "Test Country",
            location: location
        )
    }
    
    /// **NOUVELLE MÉTHODE**: Reset les flags des mocks
    private func resetMockFlags() {
        mockFirestoreService.getEventDocumentCalled = false
        mockFirestoreService.getSampleEventCalled = false
        mockGeocodingService.geocodeAddressCalled = false
    }
    
    // MARK: - Load Event Tests
    

    func testLoadEvent_WhenEventExists_ShouldLoadFromFirestore() async {
        print("\n📋 DÉBUT DU TEST testLoadEvent_WhenEventExists_ShouldLoadFromFirestore 📋")
        
        // Given
        let eventID = "test-event-id"
        print("📌 ID de l'événement à tester: \(eventID)")
        
        let mockEvent = createMockEvent(id: eventID)
        print("📌 Event mock créé: \(mockEvent)")
        print("📌 Event mock ID: \(mockEvent.id ?? "nil")")
        print("📌 Event mock title: \(mockEvent.title)")
        print("📌 Event mock date: \(mockEvent.date)")
        
        // Vérification que l'objet mockEvent est bien créé et contient un ID
        XCTAssertEqual(mockEvent.id, eventID, "L'objet Event mock doit avoir l'ID correct")
        
        // **Création du mock snapshot avec le bon ID et les données de l'événement**
        let mockSnapshot = createMockDocumentSnapshot(exists: true, event: mockEvent, documentID: eventID)
        print("📌 Mock snapshot créé - exists: \(mockSnapshot.exists), ID: \(mockSnapshot.documentID)")
        
        // **Assignation du snapshot au service avant les vérifications**
        mockFirestoreService.resetFlags()
        mockFirestoreService.mockDocument = mockSnapshot
        mockFirestoreService.shouldThrowError = false
        
        // Vérification que le mockDocument est bien configuré dans le service
        if let serviceSnapshot = mockFirestoreService.mockDocument {
            XCTAssertTrue(serviceSnapshot.exists, "Le snapshot doit exister")
            
            // Au lieu de vérifier directement documentID et data(), vérifions que le décodage fonctionne
            do {
                let decodedEvent = try serviceSnapshot.data(as: Event.self)
                XCTAssertEqual(decodedEvent.id, eventID, "L'ID décodé de l'événement doit correspondre")
                print("📌 Décodage du service snapshot réussi: \(decodedEvent.title)")
            } catch {
                XCTFail("Impossible de décoder le document: \(error)")
            }
        } else {
            XCTFail("mockDocument dans le service est nil")
        }
        
        // Vérification manuelle du décodage pour isoler le problème
        do {
            if let serviceSnapshot = mockFirestoreService.mockDocument {
                let testEvent = try serviceSnapshot.data(as: Event.self)
                print("✅ Test manuel de décodage réussi:")
                print("   - ID: \(testEvent.id ?? "nil")")
                print("   - Titre: \(testEvent.title)")
                print("   - Date: \(testEvent.date)")
            }
        } catch {
            print("❌ Test manuel de décodage échoué: \(error)")
            XCTFail("Erreur lors du décodage manuel: \(error)")
        }
        
        print("📌 État du viewModel AVANT loadEvent:")
        print("   - event: \(String(describing: viewModel.event))")
        print("   - isLoading: \(viewModel.isLoading)")
        print("   - errorMessage: '\(viewModel.errorMessage)'")
        print("   - showingError: \(viewModel.showingError)")
        
        // When - Exécution de la méthode à tester
        print("📌 Appel de loadEvent avec ID: \(eventID)")
        await viewModel.loadEvent(eventID: eventID)
        
        // Diagnostic pour voir l'état après loadEvent
        print("📌 État du viewModel APRÈS loadEvent:")
        print("   - event: \(String(describing: viewModel.event))")
        print("   - isLoading: \(viewModel.isLoading)")
        print("   - errorMessage: '\(viewModel.errorMessage)'")
        print("   - showingError: \(viewModel.showingError)")
        
        // Vérification des appels aux méthodes du service
        print("📌 Vérification des appels au service:")
        print("   - getEventDocumentCalled: \(mockFirestoreService.getEventDocumentCalled)")
        print("   - getSampleEventCalled: \(mockFirestoreService.getSampleEventCalled)")
        
        // Asserts
        // Vérifier que la bonne méthode du service a été appelée
        XCTAssertTrue(mockFirestoreService.getEventDocumentCalled, "getEventDocument devrait être appelé")
        XCTAssertFalse(mockFirestoreService.getSampleEventCalled, "getSampleEvent ne devrait pas être appelé")
        
        // Vérifier que le ViewModel est dans l'état attendu
        XCTAssertFalse(viewModel.isLoading, "isLoading devrait être false après le chargement")
        XCTAssertFalse(viewModel.showingError, "showingError devrait être false car pas d'erreur attendue")
        XCTAssertEqual(viewModel.errorMessage, "", "errorMessage devrait être vide")
        
        // Vérifier que l'event a bien été chargé
        XCTAssertNotNil(viewModel.event, "event ne devrait pas être nil après loadEvent")
        if let loadedEvent = viewModel.event {
            XCTAssertEqual(loadedEvent.id, eventID, "L'ID de l'événement chargé doit correspondre")
        }
        
        print("📋 FIN DU TEST testLoadEvent_WhenEventExists_ShouldLoadFromFirestore 📋\n")
    }

    func testLoadEvent_WhenEventDoesNotExist_ShouldLoadFromSamples() async {
        // Given
        let eventID = "non-existing-id"
        let mockEvent = createMockEvent(id: eventID)
        let mockSnapshot = createMockDocumentSnapshot(exists: false, documentID: eventID)
        
        mockFirestoreService.mockDocument = mockSnapshot
        mockFirestoreService.mockEvents = [mockEvent]
        
        // **Reset des flags avant le test**
        resetMockFlags()
        
        // When
        await viewModel.loadEvent(eventID: eventID)
        
        // Then
        XCTAssertTrue(mockFirestoreService.getEventDocumentCalled, "getEventDocument aurait dû être appelé")
        XCTAssertTrue(mockFirestoreService.getSampleEventCalled, "getSampleEvent aurait dû être appelé")
        XCTAssertNotNil(viewModel.event, "L'événement ne devrait pas être nil")
        XCTAssertEqual(viewModel.event?.id, eventID, "L'ID de l'événement chargé devrait correspondre")
        XCTAssertFalse(viewModel.isLoading, "isLoading devrait être false après le chargement")
        XCTAssertEqual(viewModel.errorMessage, "", "Aucun message d'erreur ne devrait être présent")
    }
    
    func testLoadEvent_WhenEventIDIsEmpty_ShouldSetError() async {
        // Given
        let emptyEventID = ""
        resetMockFlags()
        
        // When
        await viewModel.loadEvent(eventID: emptyEventID)
        
        // Then
        XCTAssertFalse(mockFirestoreService.getEventDocumentCalled)
        XCTAssertNil(viewModel.event)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertTrue(viewModel.errorMessage.contains("ID d'événement invalide"))
    }
    
    func testLoadEvent_WhenFirestoreThrowsError_ShouldSetError() async {
        // Given
        let eventID = "error-event-id"
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur de test"])
        resetMockFlags()
        
        // When
        await viewModel.loadEvent(eventID: eventID)
        
        // Then
        XCTAssertTrue(mockFirestoreService.getEventDocumentCalled)
        XCTAssertNil(viewModel.event)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.showingError)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur de test"))
    }
    
    // MARK: - Geocode Location Tests
    
    func testGeocodeEventLocation_WhenNoEvent_ShouldReturn() async {
        // Given
        resetMockFlags()
        
        // When
        await viewModel.geocodeEventLocation()
        
        // Then
        XCTAssertFalse(mockGeocodingService.geocodeAddressCalled)
        XCTAssertNil(viewModel.coordinates)
        XCTAssertNil(viewModel.mapImageURL)
    }
    
    func testGeocodeEventLocation_WhenEmptyLocation_ShouldReturn() async {
        // Given
        let mockEventWithEmptyLocation = Event(
            id: "test-id",
            title: "Test Event",
            description: "Description",
            date: Date(),
            location: "", // ← Location vide
            organizer: "Organisateur",
            organizerImageURL: "https://example.com/organizer.jpg",
            imageURL: "https://example.com/image.jpg",
            category: "Test",
            tags: ["test"],
            createdAt: Date()
        )
        
        // **Définir l'événement directement**
        viewModel.event = mockEventWithEmptyLocation
        resetMockFlags()
        
        // When
        await viewModel.geocodeEventLocation()
        
        // Then
        XCTAssertFalse(mockGeocodingService.geocodeAddressCalled, "geocodeAddress ne devrait pas être appelé car la location est vide")
        XCTAssertNil(viewModel.coordinates, "Les coordonnées devraient rester nil")
        XCTAssertNil(viewModel.mapImageURL, "L'URL de l'image de carte devrait rester nil")
    }
    
    func testGeocodeEventLocation_WhenCoordinatesAlreadyExist_ShouldGenerateMapURL() async {
        // Given
        let mockEvent = createMockEvent()
        viewModel.event = mockEvent
        
        let coordinates = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        viewModel.coordinates = coordinates
        resetMockFlags()
        
        // When
        await viewModel.geocodeEventLocation()
        
        // Then
        XCTAssertNotNil(viewModel.mapImageURL, "L'URL de l'image de carte ne devrait pas être nil")
        XCTAssertTrue(viewModel.mapImageURL!.absoluteString.contains("staticmap"), "L'URL devrait contenir 'staticmap'")
        XCTAssertFalse(mockGeocodingService.geocodeAddressCalled, "geocodeAddress ne devrait pas être appelé car les coordonnées existent déjà")
    }
    
    func testGeocodeEventLocation_WhenSuccess_ShouldSetCoordinatesAndGenerateMapURL() async throws {
        // Given
        let mockEvent = createMockEvent()
        viewModel.event = mockEvent
        
        let latitude = 48.8566
        let longitude = 2.3522
        let mockPlacemark = createMockPlacemark(latitude: latitude, longitude: longitude)
        mockGeocodingService.mockPlacemarks = [mockPlacemark]
        
        resetMockFlags()
        viewModel.coordinates = nil // Force le géocodage
        
        // When
        await viewModel.geocodeEventLocation()
        
        // Then
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
        
        let coordinates = try XCTUnwrap(viewModel.coordinates, "Les coordonnées ne devraient pas être nil")
        XCTAssertEqual(coordinates.latitude, latitude, accuracy: 0.0001, "La latitude devrait correspondre")
        XCTAssertEqual(coordinates.longitude, longitude, accuracy: 0.0001, "La longitude devrait correspondre")
        
        XCTAssertNotNil(viewModel.mapImageURL, "L'URL de l'image de carte ne devrait pas être nil")
    }
    
    func testGeocodeEventLocation_WhenGeocodingFails_ShouldSetErrorMessage() async {
        // Given
        let mockEvent = createMockEvent()
        viewModel.event = mockEvent
        
        mockGeocodingService.shouldThrowError = true
        mockGeocodingService.mockError = NSError(domain: "GeocodingError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur de géocodage"])
        resetMockFlags()
        
        // When
        await viewModel.geocodeEventLocation()
        
        // Then
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
        XCTAssertNil(viewModel.coordinates)
        XCTAssertNil(viewModel.mapImageURL)
        XCTAssertTrue(viewModel.errorMessage.contains("Erreur de géocodage"))
    }
    
    func testGeocodeEventLocation_WhenNoPlacemarkFound_ShouldSetErrorMessage() async {
        // Given
        let mockEvent = createMockEvent()
        viewModel.event = mockEvent
        
        mockGeocodingService.mockPlacemarks = [] // ← Aucun résultat
        resetMockFlags()
        
        // When
        await viewModel.geocodeEventLocation()
        
        // Then
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled)
        XCTAssertNil(viewModel.coordinates)
        XCTAssertNil(viewModel.mapImageURL)
        XCTAssertTrue(viewModel.errorMessage.contains("Impossible de localiser l'adresse"))
    }
    
    // MARK: - Map URL Generation Tests
    
    func testGenerateMapImageURL_WhenNoCoordinates_ShouldNotGenerateURL() {
        // Given
        viewModel.coordinates = nil
        
        // When
        viewModel.generateMapImageURL()
        
        // Then
        XCTAssertNil(viewModel.mapImageURL)
    }
    
    func testGenerateMapImageURL_WhenValidCoordinates_ShouldGenerateURL() {
        // Given
        let coordinates = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        viewModel.coordinates = coordinates
        
        // When
        viewModel.generateMapImageURL()
        
        // Then
        XCTAssertNotNil(viewModel.mapImageURL)
        XCTAssertTrue(viewModel.mapImageURL!.absoluteString.contains("staticmap"))
        XCTAssertTrue(viewModel.mapImageURL!.absoluteString.contains("48.8566"))
        XCTAssertTrue(viewModel.mapImageURL!.absoluteString.contains("2.3522"))
    }
    
    // MARK: - Integration Tests
    
    func testLoadEventWithAutoGeocode_WhenEnabled_ShouldGeocodeAutomatically() async {
        // Given
        let viewModelWithAutoGeocode = EventDetailsViewModel(
            firestoreService: mockFirestoreService,
            geocodingService: mockGeocodingService,
            mapNetworkService: mockMapNetworkService,
            configurationService: mockConfigurationService,
            isTestMode: true,
            shouldAutoGeocode: true // ← Activer le géocodage automatique
        )
        
        let eventID = "test-event-id"
        let mockEvent = createMockEvent(id: eventID)
        let mockSnapshot = createMockDocumentSnapshot(exists: true, event: mockEvent, documentID: eventID)
        
        mockFirestoreService.mockDocument = mockSnapshot
        resetMockFlags()
        
        // When
        await viewModelWithAutoGeocode.loadEvent(eventID: eventID)
        
        // Then
        XCTAssertTrue(mockGeocodingService.geocodeAddressCalled, "Le géocodage automatique devrait être appelé")
        XCTAssertNotNil(viewModelWithAutoGeocode.coordinates, "Les coordonnées devraient être définies")
    }

}
