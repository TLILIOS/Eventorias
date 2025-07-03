import Foundation
import CoreLocation
import XCTest
@testable import Eventorias

/// Mock pour EventServiceProtocol facilitant les tests unitaires
final class MockEventService: EventServiceProtocol {
    // Tracking des appels pour la vérification dans les tests
    var fetchEventsCalled = false
    var searchEventsCalled = false
    var filterEventsByCategoryCalled = false
    var getEventsSortedByDateCalled = false
    var addSampleEventsCalled = false
    var isEventsCollectionEmptyCalled = false
    var createEventCalled = false
    var uploadImageCalled = false
    var getCoordinatesForAddressCalled = false
    
    // Variables pour contrôler le comportement des fonctions
    var shouldThrowError = false
    var mockError: Error = NSError(domain: "MockEventError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée d'événement"])
    
    // Callbacks pour les tests
    var onImageUploaded: ((String) -> Void)? = nil
    var captureImageUploadState: (() -> Void)? = nil
    
    // Données à retourner par les méthodes mock
    var eventsToReturn: [Event] = []
    var isCollectionEmptyToReturn = true
    var eventIdToReturn = "mock-event-id"
    var imageURLToReturn = "https://example.com/mock-image.jpg"
    var coordinatesToReturn = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris
    
    /// Fetches all events from the data source
    func fetchEvents() async throws -> [Event] {
        fetchEventsCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return eventsToReturn
    }
    
    /// Searches for events based on a query string
    func searchEvents(query: String) async throws -> [Event] {
        searchEventsCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Filtrer les événements qui correspondent à la requête
        return eventsToReturn.filter { $0.title.lowercased().contains(query.lowercased()) }
    }
    
    /// Filters events by category
    func filterEventsByCategory(category: EventCategory) async throws -> [Event] {
        filterEventsByCategoryCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Filtrer les événements par catégorie
        return eventsToReturn.filter { $0.category == category }
    }
    
    /// Gets events sorted by date
    func getEventsSortedByDate(ascending: Bool) async throws -> [Event] {
        getEventsSortedByDateCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Trier les événements par date
        return eventsToReturn.sorted { event1, event2 in
            if ascending {
                return event1.date < event2.date
            } else {
                return event1.date > event2.date
            }
        }
    }
    
    /// Adds sample events to the data source
    func addSampleEvents() async throws {
        addSampleEventsCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Ne pas écraser les événements configurés pour les tests
        // Si aucun événement n'est configuré, utiliser les échantillons
        if eventsToReturn.isEmpty {
            eventsToReturn = Event.sampleEvents
        }
        // Sinon, conserver les événements déjà configurés pour le test
    }
    
    /// Checks if the events collection is empty
    func isEventsCollectionEmpty() async throws -> Bool {
        isEventsCollectionEmptyCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return isCollectionEmptyToReturn
    }
    
    /// Creates a new event
    func createEvent(title: String, description: String, date: Date, location: String, imageURL: String?) async throws -> String {
        createEventCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Créer un nouvel événement et l'ajouter à notre collection de test
        let newEvent = Event(
            id: eventIdToReturn,
            title: title,
            description: description,
            date: date,
            location: location,
            organizer: "Test Organizer",
            organizerImageURL: nil,
            imageURL: imageURL,
            category: .other,
            tags: ["Test"],
            createdAt: Date()
        )
        
        eventsToReturn.append(newEvent)
        return eventIdToReturn
    }
    
    /// Uploads an image to storage
    func uploadImage(imageData: Data) async throws -> String {
        uploadImageCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Capturer l'état juste avant de retourner l'URL (important pour les tests)
        captureImageUploadState?() 
        
        // Appeler le callback onImageUploaded s'il existe
        onImageUploaded?(imageURLToReturn)
        
        return imageURLToReturn
    }
    
    /// Gets coordinates for an address via geocoding
    func getCoordinatesForAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        getCoordinatesForAddressCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return coordinatesToReturn
    }
    
    // Méthodes helper pour les tests
    func reset() {
        fetchEventsCalled = false
        searchEventsCalled = false
        filterEventsByCategoryCalled = false
        getEventsSortedByDateCalled = false
        addSampleEventsCalled = false
        isEventsCollectionEmptyCalled = false
        createEventCalled = false
        uploadImageCalled = false
        getCoordinatesForAddressCalled = false
        shouldThrowError = false
    }
}
