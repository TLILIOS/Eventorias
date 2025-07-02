//
//  EventServiceTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
import CoreLocation
@testable import Eventorias
@MainActor
final class EventServiceTests: XCTestCase {
    
    var mockEventService: MockEventService!
    
    override func setUp() {
        super.setUp()
        mockEventService = MockEventService()
    }
    
    override func tearDown() {
        mockEventService = nil
        super.tearDown()
    }
    
    // MARK: - Tests de récupération des événements
    
    func testFetchEventsSuccess() async {
        // Arrange
        let sampleEvent1 = Event(
            id: "event1",
            title: "Événement test 1",
            description: "Description de l'événement 1",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur test",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Test",
            tags: ["Test"],
            createdAt: Date()
        )
        
        let sampleEvent2 = Event(
            id: "event2",
            title: "Événement test 2",
            description: "Description de l'événement 2",
            date: Date().addingTimeInterval(86400), // +1 jour
            location: "Lyon",
            organizer: "Organisateur test",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Test",
            tags: ["Test"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [sampleEvent1, sampleEvent2]
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let events = try await mockEventService.fetchEvents()
            
            // Assert
            XCTAssertTrue(mockEventService.fetchEventsCalled, "La méthode fetchEvents n'a pas été appelée")
            XCTAssertEqual(events.count, 2, "Le nombre d'événements récupérés ne correspond pas")
            XCTAssertEqual(events[0].id, "event1", "L'ID du premier événement ne correspond pas")
            XCTAssertEqual(events[1].id, "event2", "L'ID du deuxième événement ne correspond pas")
        } catch {
            XCTFail("La récupération des événements a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testFetchEventsFailure() async {
        // Arrange
        mockEventService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await mockEventService.fetchEvents()
            XCTFail("La récupération des événements a réussi alors qu'elle devrait échouer")
        } catch {
            XCTAssertTrue(mockEventService.fetchEventsCalled, "La méthode fetchEvents n'a pas été appelée")
        }
    }
    
    // MARK: - Tests de recherche d'événements
    
    func testSearchEventsSuccess() async {
        // Arrange
        let matchingEvent = Event(
            id: "event1",
            title: "Concert de musique",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Musique",
            tags: ["Musique"],
            createdAt: Date()
        )
        
        let nonMatchingEvent = Event(
            id: "event2",
            title: "Exposition d'art",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Art",
            tags: ["Art"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [matchingEvent, nonMatchingEvent]
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let events = try await mockEventService.searchEvents(query: "Concert")
            
            // Assert
            XCTAssertTrue(mockEventService.searchEventsCalled, "La méthode searchEvents n'a pas été appelée")
            XCTAssertEqual(events.count, 1, "Le nombre d'événements recherchés ne correspond pas")
            XCTAssertEqual(events[0].id, "event1", "L'ID de l'événement recherché ne correspond pas")
        } catch {
            XCTFail("La recherche d'événements a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testSearchEventsNoResults() async {
        // Arrange
        let event1 = Event(
            id: "event1",
            title: "Concert de musique",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Musique",
            tags: ["Musique"],
            createdAt: Date()
        )
        
        let event2 = Event(
            id: "event2",
            title: "Exposition d'art",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Art",
            tags: ["Art"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [event1, event2]
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let events = try await mockEventService.searchEvents(query: "Théâtre")
            
            // Assert
            XCTAssertTrue(mockEventService.searchEventsCalled, "La méthode searchEvents n'a pas été appelée")
            XCTAssertEqual(events.count, 0, "La recherche devrait retourner 0 événement")
        } catch {
            XCTFail("La recherche d'événements a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests de filtrage par catégorie
    
    func testFilterEventsByCategorySuccess() async {
        // Arrange
        let musicEvent = Event(
            id: "event1",
            title: "Concert de musique",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Musique",
            tags: ["Musique"],
            createdAt: Date()
        )
        
        let artEvent = Event(
            id: "event2",
            title: "Exposition d'art",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Art",
            tags: ["Art"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [musicEvent, artEvent]
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let events = try await mockEventService.filterEventsByCategory(category: "Musique")
            
            // Assert
            XCTAssertTrue(mockEventService.filterEventsByCategoryCalled, "La méthode filterEventsByCategory n'a pas été appelée")
            XCTAssertEqual(events.count, 1, "Le nombre d'événements filtrés ne correspond pas")
            XCTAssertEqual(events[0].id, "event1", "L'ID de l'événement filtré ne correspond pas")
        } catch {
            XCTFail("Le filtrage des événements a échoué alors qu'il devrait réussir: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests de tri par date
    
    func testGetEventsSortedByDateAscending() async {
        // Arrange
        let oldEvent = Event(
            id: "event1",
            title: "Ancien événement",
            description: "Description",
            date: Date().addingTimeInterval(-86400), // -1 jour
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Test",
            tags: ["Test"],
            createdAt: Date()
        )
        
        let newEvent = Event(
            id: "event2",
            title: "Nouvel événement",
            description: "Description",
            date: Date().addingTimeInterval(86400), // +1 jour
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Test",
            tags: ["Test"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [newEvent, oldEvent] // Ordre inversé intentionnellement
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let events = try await mockEventService.getEventsSortedByDate(ascending: true)
            
            // Assert
            XCTAssertTrue(mockEventService.getEventsSortedByDateCalled, "La méthode getEventsSortedByDate n'a pas été appelée")
            XCTAssertEqual(events.count, 2, "Le nombre d'événements triés ne correspond pas")
            XCTAssertEqual(events[0].id, "event1", "Le premier événement devrait être le plus ancien")
            XCTAssertEqual(events[1].id, "event2", "Le deuxième événement devrait être le plus récent")
        } catch {
            XCTFail("Le tri des événements a échoué alors qu'il devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testGetEventsSortedByDateDescending() async {
        // Arrange
        let oldEvent = Event(
            id: "event1",
            title: "Ancien événement",
            description: "Description",
            date: Date().addingTimeInterval(-86400), // -1 jour
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Test",
            tags: ["Test"],
            createdAt: Date()
        )
        
        let newEvent = Event(
            id: "event2",
            title: "Nouvel événement",
            description: "Description",
            date: Date().addingTimeInterval(86400), // +1 jour
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: "Test",
            tags: ["Test"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [oldEvent, newEvent] // Ordre inversé intentionnellement
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let events = try await mockEventService.getEventsSortedByDate(ascending: false)
            
            // Assert
            XCTAssertTrue(mockEventService.getEventsSortedByDateCalled, "La méthode getEventsSortedByDate n'a pas été appelée")
            XCTAssertEqual(events.count, 2, "Le nombre d'événements triés ne correspond pas")
            XCTAssertEqual(events[0].id, "event2", "Le premier événement devrait être le plus récent")
            XCTAssertEqual(events[1].id, "event1", "Le deuxième événement devrait être le plus ancien")
        } catch {
            XCTFail("Le tri des événements a échoué alors qu'il devrait réussir: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests de vérification de collection vide
    
    func testIsEventsCollectionEmpty() async {
        // Arrange
        mockEventService.isCollectionEmptyToReturn = true
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let isEmpty = try await mockEventService.isEventsCollectionEmpty()
            
            // Assert
            XCTAssertTrue(mockEventService.isEventsCollectionEmptyCalled, "La méthode isEventsCollectionEmpty n'a pas été appelée")
            XCTAssertTrue(isEmpty, "La collection devrait être vide")
        } catch {
            XCTFail("La vérification a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests de création d'événement
    
    func testCreateEventSuccess() async {
        // Arrange
        mockEventService.eventIdToReturn = "new-event-id"
        mockEventService.shouldThrowError = false
        let title = "Nouvel événement"
        let description = "Description de l'événement"
        let date = Date().addingTimeInterval(86400) // +1 jour
        let location = "Paris, France"
        let imageURL = "https://example.com/image.jpg"
        
        // Act
        do {
            let eventId = try await mockEventService.createEvent(
                title: title,
                description: description,
                date: date,
                location: location,
                imageURL: imageURL
            )
            
            // Assert
            XCTAssertTrue(mockEventService.createEventCalled, "La méthode createEvent n'a pas été appelée")
            XCTAssertEqual(eventId, "new-event-id", "L'ID de l'événement créé ne correspond pas")
        } catch {
            XCTFail("La création d'événement a échoué alors qu'elle devrait réussir: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests d'upload d'image
    
    func testUploadImageSuccess() async {
        // Arrange
        let imageData = Data(repeating: 0, count: 100) // Données d'image simulées
        mockEventService.imageURLToReturn = "https://example.com/uploaded-image.jpg"
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let imageURL = try await mockEventService.uploadImage(imageData: imageData)
            
            // Assert
            XCTAssertTrue(mockEventService.uploadImageCalled, "La méthode uploadImage n'a pas été appelée")
            XCTAssertEqual(imageURL, "https://example.com/uploaded-image.jpg", "L'URL de l'image ne correspond pas")
        } catch {
            XCTFail("L'upload d'image a échoué alors qu'il devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testUploadImageFailure() async {
        // Arrange
        let imageData = Data(repeating: 0, count: 100) // Données d'image simulées
        mockEventService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await mockEventService.uploadImage(imageData: imageData)
            XCTFail("L'upload d'image a réussi alors qu'il devrait échouer")
        } catch {
            XCTAssertTrue(mockEventService.uploadImageCalled, "La méthode uploadImage n'a pas été appelée")
        }
    }
    
    // MARK: - Tests de géocodage
    
    func testGetCoordinatesForAddressSuccess() async {
        // Arrange
        let address = "Paris, France"
        let expectedCoordinates = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris
        mockEventService.coordinatesToReturn = expectedCoordinates
        mockEventService.shouldThrowError = false
        
        // Act
        do {
            let coordinates = try await mockEventService.getCoordinatesForAddress(address)
            
            // Assert
            XCTAssertTrue(mockEventService.getCoordinatesForAddressCalled, "La méthode getCoordinatesForAddress n'a pas été appelée")
            XCTAssertEqual(coordinates.latitude, expectedCoordinates.latitude, accuracy: 0.0001, "La latitude ne correspond pas")
            XCTAssertEqual(coordinates.longitude, expectedCoordinates.longitude, accuracy: 0.0001, "La longitude ne correspond pas")
        } catch {
            XCTFail("Le géocodage a échoué alors qu'il devrait réussir: \(error.localizedDescription)")
        }
    }
    
    func testGetCoordinatesForAddressFailure() async {
        // Arrange
        let address = "Adresse inexistante"
        mockEventService.shouldThrowError = true
        
        // Act & Assert
        do {
            _ = try await mockEventService.getCoordinatesForAddress(address)
            XCTFail("Le géocodage a réussi alors qu'il devrait échouer")
        } catch {
            XCTAssertTrue(mockEventService.getCoordinatesForAddressCalled, "La méthode getCoordinatesForAddress n'a pas été appelée")
        }
    }
}
