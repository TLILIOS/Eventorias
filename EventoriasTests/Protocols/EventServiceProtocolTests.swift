//
//  EventServiceProtocolTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
import CoreLocation
@testable import Eventorias

final class EventServiceProtocolTests: XCTestCase {

    // MARK: - Tests de conformité au protocole
    
    func testEventServiceProtocolConformance() {
        // Arrange
        let eventService = EventService()
        
        // Act & Assert
        XCTAssertTrue(eventService is EventServiceProtocol, "EventService doit se conformer à EventServiceProtocol")
    }
    
    func testMockEventServiceProtocolConformance() {
        // Arrange
        let mockEventService = MockEventService()
        
        // Act & Assert
        XCTAssertTrue(mockEventService is EventServiceProtocol, "MockEventService doit se conformer à EventServiceProtocol")
    }
    
    // MARK: - Tests de comportement polymorphique
    
    func testEventProtocolBehaviorWithDifferentImplementations() async {
        // Arrange
        let mockEventService = MockEventService()
        
        // Nous utilisons seulement le mock pour les tests unitaires
        let eventServices: [EventServiceProtocol] = [mockEventService]
        
        // Préparation des données de test
        let sampleEvent1 = Event(
            id: "event1",
            title: "Événement test 1",
            description: "Description",
            date: Date(),
            location: "Paris",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: EventCategory.fromString("Test"),
            tags: ["Test"],
            createdAt: Date()
        )
        
        let sampleEvent2 = Event(
            id: "event2",
            title: "Événement test 2",
            description: "Description",
            date: Date().addingTimeInterval(86400),
            location: "Lyon",
            organizer: "Organisateur",
            organizerImageURL: nil,
            imageURL: nil,
            category: EventCategory.fromString("Autre"),
            tags: ["Autre"],
            createdAt: Date()
        )
        
        mockEventService.eventsToReturn = [sampleEvent1, sampleEvent2]
        
        // Test comportement polymorphique - fetchEvents
        for (index, service) in eventServices.enumerated() {
            do {
                let events = try await service.fetchEvents()
                XCTAssertEqual(events.count, 2, "L'implémentation \(index) devrait retourner 2 événements")
            } catch {
                XCTFail("L'implémentation \(index) a échoué lors de l'appel fetchEvents: \(error)")
            }
        }
        
        // Test comportement polymorphique - filterEventsByCategory
        for (index, service) in eventServices.enumerated() {
            do {
                let events = try await service.filterEventsByCategory(category: EventCategory.fromString("Test"))
                XCTAssertEqual(events.count, 1, "L'implémentation \(index) devrait retourner 1 événement pour la catégorie 'Test'")
                XCTAssertEqual(events.first?.id, "event1", "L'implémentation \(index) devrait retourner l'événement avec l'ID 'event1'")
            } catch {
                XCTFail("L'implémentation \(index) a échoué lors de l'appel filterEventsByCategory: \(error)")
            }
        }
    }
    
    // MARK: - Tests des méthodes asynchrones
    
    func testAsyncMethodsWithMockImplementation() async {
        // Arrange
        let mockEventService = MockEventService()
        mockEventService.shouldThrowError = false
        
        // Test de création d'événement
        do {
            let eventId = try await mockEventService.createEvent(
                title: "Nouvel événement",
                description: "Description test",
                date: Date(),
                location: "Paris",
                imageURL: nil
            )
            
            XCTAssertEqual(eventId, mockEventService.eventIdToReturn, "L'ID de l'événement créé ne correspond pas")
            XCTAssertEqual(mockEventService.eventsToReturn.last?.title, "Nouvel événement", "Le titre de l'événement créé ne correspond pas")
        } catch {
            XCTFail("La méthode createEvent du protocole a échoué: \(error.localizedDescription)")
        }
        
        // Test d'upload d'image
        do {
            let imageData = Data([0, 1, 2, 3, 4]) // Données d'image simulées
            let url = try await mockEventService.uploadImage(imageData: imageData)
            
            XCTAssertEqual(url, mockEventService.imageURLToReturn, "L'URL de l'image uploadée ne correspond pas")
        } catch {
            XCTFail("La méthode uploadImage du protocole a échoué: \(error.localizedDescription)")
        }
        
        // Test de géocodage
        do {
            let coordinates = try await mockEventService.getCoordinatesForAddress("Paris")
            
            XCTAssertEqual(coordinates.latitude, mockEventService.coordinatesToReturn.latitude, accuracy: 0.0001)
            XCTAssertEqual(coordinates.longitude, mockEventService.coordinatesToReturn.longitude, accuracy: 0.0001)
        } catch {
            XCTFail("La méthode getCoordinatesForAddress du protocole a échoué: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Tests des erreurs possibles
    
    func testErrorHandlingInProtocolMethods() async {
        // Arrange
        let mockEventService = MockEventService()
        mockEventService.shouldThrowError = true
        
        // Test de récupération d'événements avec erreur
        do {
            _ = try await mockEventService.fetchEvents()
            XCTFail("La méthode fetchEvents aurait dû échouer")
        } catch {
            XCTAssertTrue(mockEventService.fetchEventsCalled, "La méthode fetchEvents n'a pas été appelée")
        }
        
        // Test de recherche d'événements avec erreur
        do {
            _ = try await mockEventService.searchEvents(query: "test")
            XCTFail("La méthode searchEvents aurait dû échouer")
        } catch {
            XCTAssertTrue(mockEventService.searchEventsCalled, "La méthode searchEvents n'a pas été appelée")
        }
    }
}
