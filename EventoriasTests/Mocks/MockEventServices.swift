import Foundation
import CoreLocation
import Firebase
@testable import Eventorias

// MARK: - Mock Firestore Service

class MockFirestoreDocumentSnapshot: DocumentSnapshotProtocol {
    var exists: Bool
    var mockEvent: Event?
    var throwErrorOnData: Bool
    var errorToThrow: Error?
    
    init(exists: Bool = true, mockEvent: Event? = nil, throwErrorOnData: Bool = false, errorToThrow: Error? = nil) {
        self.exists = exists
        self.mockEvent = mockEvent
        self.throwErrorOnData = throwErrorOnData
        self.errorToThrow = errorToThrow
    }
    
    func data<T: Decodable>(as type: T.Type) throws -> T {
        if throwErrorOnData {
            throw errorToThrow ?? EventDetailsError.noData
        }
        
        guard let event = mockEvent as? T else {
            throw EventDetailsError.noData
        }
        
        return event
    }
}

class MockEventFirestoreService: EventFirestoreService {
    var eventToReturn: Event?
    var errorToThrow: Error?
    var getEventDocumentCalled = false
    var getSampleEventCalled = false
    var lastEventIDRequested: String = ""
    var mockDocumentSnapshot: MockFirestoreDocumentSnapshot?
    
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol {
        getEventDocumentCalled = true
        lastEventIDRequested = eventID
        
        if let error = errorToThrow {
            throw error
        }
        
        // Return our mock document snapshot or create one on the fly
        if let mockSnapshot = mockDocumentSnapshot {
            return mockSnapshot
        } else if let event = eventToReturn {
            let mockSnapshot = MockFirestoreDocumentSnapshot(exists: true, mockEvent: event)
            return mockSnapshot
        } else {
            let mockSnapshot = MockFirestoreDocumentSnapshot(exists: false)
            return mockSnapshot
        }
    }
    
    func getSampleEvent(eventID: String) throws -> Event {
        getSampleEventCalled = true
        lastEventIDRequested = eventID
        
        if let error = errorToThrow {
            throw error
        }
        
        if let event = eventToReturn ?? Event.sampleEvents.first(where: { $0.id == eventID }) {
            return event
        }
        
        throw EventDetailsError.noData
    }
}

// MARK: - Mock Geocoding Service

class MockGeocodingService: GeocodingService {
    // Mock behavior configuration
    var mockCoordinates: CLLocationCoordinate2D?
    var geocodeAddressCalled = false
    var lastAddressGeocoded: String = ""
    var shouldThrowError = false
    var errorToThrow: Error = EventDetailsError.geocodingError
    var shouldReturnEmptyPlacemarks = false
    var geocodingCancelled = false
    
    // ✅ CORRECTION: Améliorer la simulation de géocodage
    func geocodeAddress(_ address: String) async throws -> [PlacemarkProtocol] {
        geocodeAddressCalled = true
        lastAddressGeocoded = address
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        if shouldReturnEmptyPlacemarks {
            return []
        }
        
        // ✅ CORRECTION: Créer un mock placemark avec les coordonnées
        if let coordinates = mockCoordinates {
            let mockLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            
            // Créer un mock placemark personnalisé qui implémente PlacemarkProtocol
            let mockPlacemark = MockPlacemark(location: mockLocation)
            return [mockPlacemark]
        }
        
        return []
    }
    
    func cancelGeocoding() {
        geocodingCancelled = true
    }
}

// MARK: - Mock Placemark pour les tests

class MockPlacemark: PlacemarkProtocol {
    private let _location: CLLocation
    
    init(location: CLLocation) {
        self._location = location
    }
    
    var location: CLLocation? {
        return _location
    }
    
    // coordinate est fourni par l'extension du protocole
}

// MARK: - Mock Map Network Service

class MockMapNetworkService: MapNetworkService {
    var validateURLCalled = false
    var lastURLValidated: URL?
    var mockMapImageURL: URL?
    var mockSuccess = true
    var shouldThrowError = false
    var errorToThrow = MapError.networkError("Mock network error")
    
    func validateMapImageURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        validateURLCalled = true
        lastURLValidated = url
        
        // ✅ CORRECTION: Simuler une validation asynchrone réaliste
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
            if self.shouldThrowError || !self.mockSuccess {
                completion(.failure(self.errorToThrow))
            } else {
                completion(.success(()))
            }
        }
    }
    
    func getMapImageURL() -> URL? {
        return mockMapImageURL
    }
}

// MARK: - Mock Configuration Service

class MockConfigurationService: ConfigurationService {
    // ✅ CORRECTION: Utiliser une clé API de plus de 20 caractères par défaut
    var mockGoogleMapsAPIKey: String = "mock-api-key-with-sufficient-length-for-testing"
    var getGoogleMapsAPIKeyCalled = false
    
    var googleMapsAPIKey: String {
        getGoogleMapsAPIKeyCalled = true
        return mockGoogleMapsAPIKey
    }
}

// MARK: - Mock DocumentSnapshot pour testing

class MockDocumentSnapshot {
    var exists: Bool
    private var mockData: [String: Any]?
    
    init(exists: Bool, data: [String: Any]? = nil) {
        self.exists = exists
        self.mockData = data
    }
    
    func data() -> [String: Any]? {
        return mockData
    }
}
