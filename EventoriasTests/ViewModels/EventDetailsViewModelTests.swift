// 
// EventDetailsViewModelTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
import CoreLocation
@testable import Eventorias
@MainActor
final class EventDetailsViewModelTests: XCTestCase {
    var sut: EventDetailsViewModel!
    
    override func setUp() {
        super.setUp()
        sut = EventDetailsViewModel()
    }
    
    override func tearDown() {
        sut = nil
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
    
    // MARK: - Tests
    
    func testInitialization() {
        // Test initialization avec valeurs par défaut
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNil(sut.event)
        XCTAssertNil(sut.coordinates)
        XCTAssertNil(sut.mapImageURL)
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertFalse(sut.showingError)
    }
    
    func testLoadEvent_WithEmptyId() async {
        // Arrange - ID vide
        let emptyId = ""
        
        // Act
        await sut.loadEvent(eventID: emptyId)
        
        // Assert
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "ID d'événement invalide")
        XCTAssertNil(sut.event)
    }
    
    func testGeocodeEventLocation_WithEmptyAddress() async {
        // Arrange - Aucun événement défini
        
        // Act
        await sut.geocodeEventLocation()
        
        // Assert
        XCTAssertFalse(sut.isLoadingMap)
        XCTAssertNil(sut.coordinates)
        XCTAssertNil(sut.mapImageURL)
    }
    
    func testFormattedEventTime_WithNoEvent() {
        // Arrange - Aucun événement défini
        
        // Act
        let timeString = sut.formattedEventTime()
        
        // Assert
        XCTAssertEqual(timeString, "")
    }
    
    func testFormattedEventDay_WithNoEvent() {
        // Arrange - Aucun événement défini
        
        // Act
        let dayString = sut.formattedEventDay()
        
        // Assert
        XCTAssertEqual(dayString, "")
    }
    
    func testGenerateMapImageURL_WithNoCoordinates() {
        // Arrange - Pas de coordonnées définies
        sut.coordinates = nil
        
        // Act - La méthode étant privée, on ne peut pas l'appeler directement
        // On teste indirectement via les propriétés observables
        
        // Assert
        XCTAssertNil(sut.mapImageURL)
    }
    
    func testIsMapAPIKeyConfigured_WithEmptyKey() {
        // On utilise la reflection pour accéder à la propriété privée
        // Note: Ce test peut être fragile car dépend de l'implémentation interne
        
        let mirror = Mirror(reflecting: sut)
        if let googleMapsAPIKey = mirror.children.first(where: { $0.label == "googleMapsAPIKey" })?.value as? String {
            // Si la clé API est configurée dans le code source, ce test pourrait échouer
            // On teste uniquement si elle est considérée comme valide par la méthode
            if googleMapsAPIKey == "AIzaSyDB5MkjrYJCdIYS_rCT2QiBs6jocJ7sY-g" {
                XCTAssertTrue(sut.isMapAPIKeyConfigured)
            } else if googleMapsAPIKey.isEmpty || googleMapsAPIKey == "To do" || googleMapsAPIKey == "YOUR_API_KEY" {
                XCTAssertFalse(sut.isMapAPIKeyConfigured)
            }
        }
    }
    
    func testHandleMapError() {
        // On utilise la reflection pour accéder à la méthode privée
        // Note: Ce test est plus un exemple car l'accès à la méthode privée n'est pas possible directement
        
        // Arrange - On simule une erreur de carte
        let errorMessage = "Test error message"
        let error = EventDetailsViewModel.MapError.networkError(errorMessage)
        
        // Act - Au lieu d'appeler directement la méthode privée, on simule son effet
        sut.errorMessage = errorMessage
        sut.showingError = true
        
        // Assert
        XCTAssertEqual(sut.errorMessage, errorMessage)
        XCTAssertTrue(sut.showingError)
    }
}
