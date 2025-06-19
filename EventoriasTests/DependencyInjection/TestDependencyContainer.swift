//
//  TestDependencyContainer.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import CoreLocation
@testable import Eventorias

/// Container d'injection de dépendances pour les tests
class TestDependencyContainer: DependencyContainerProtocol {
    // Services mockés par défaut
    var mockEventService: MockEventService
    var mockFirestoreService: MockFirestoreService
    var mockGeocodingService: MockGeocodingService
    var mockMapNetworkService: MockMapNetworkService
    var mockConfigurationService: MockConfigurationService
    var mockAuthService: MockAuthService
    var mockKeychainService: MockKeychainService
    var mockStorageService: MockStorageService
    var mockAPIService: MockAPIService
    
    /// Initialisation avec des mocks par défaut
    init() {
        // Initialisation des services mockés
        self.mockEventService = MockEventService()
        self.mockFirestoreService = MockFirestoreService()
        self.mockGeocodingService = MockGeocodingService()
        self.mockMapNetworkService = MockMapNetworkService()
        self.mockConfigurationService = MockConfigurationService()
        self.mockAuthService = MockAuthService()
        self.mockKeychainService = MockKeychainService()
        self.mockStorageService = MockStorageService()
        self.mockAPIService = MockAPIService()
    }
    
    /// Accès aux services (implémentation de DependencyContainerProtocol)
    func eventService() -> EventServiceProtocol {
        return mockEventService
    }
    
    func firestoreService() -> EventFirestoreService {
        return mockFirestoreService
    }
    
    func geocodingService() -> GeocodingService {
        return mockGeocodingService
    }
    
    func mapNetworkService() -> MapNetworkService {
        return mockMapNetworkService
    }
    
    func configurationService() -> ConfigurationService {
        return mockConfigurationService
    }
    
    func authenticationService() -> AuthenticationServiceProtocol {
        return mockAuthService
    }
    
    func keychainService() -> KeychainServiceProtocol {
        return mockKeychainService
    }
    
    func storageService() -> StorageServiceProtocol {
        return mockStorageService
    }
    
    func apiService() -> APIServiceProtocol {
        return mockAPIService
    }
}

/// Mock pour FirestoreService
class MockFirestoreService: EventFirestoreService {
    // Flags pour tracer les appels
    var fetchEventCalled = false
    var fetchEventsCalled = false
    var addEventCalled = false
    var updateEventCalled = false
    var deleteEventCalled = false
    var isCollectionEmptyCalled = false
    
    // Données de retour
    var mockEvents: [Event] = []
    var mockEvent: Event?
    var mockError: Error?
    var mockIsEmpty = false
    var mockEventId = "mock_event_id"
    
    // Implémentation des méthodes
    func fetchEvent(withId id: String) async throws -> Event {
        fetchEventCalled = true
        if let error = mockError {
            throw error
        }
        if let event = mockEvent {
            return event
        }
        throw NSError(domain: "MockFirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Event not found"])
    }
    
    func fetchEvents() async throws -> [Event] {
        fetchEventsCalled = true
        if let error = mockError {
            throw error
        }
        return mockEvents
    }
    
    func addEvent(_ event: Event) async throws -> String {
        addEventCalled = true
        if let error = mockError {
            throw error
        }
        return mockEventId
    }
    
    func updateEvent(_ event: Event) async throws {
        updateEventCalled = true
        if let error = mockError {
            throw error
        }
    }
    
    func deleteEvent(withId id: String) async throws {
        deleteEventCalled = true
        if let error = mockError {
            throw error
        }
    }
    
    func isCollectionEmpty() async throws -> Bool {
        isCollectionEmptyCalled = true
        if let error = mockError {
            throw error
        }
        return mockIsEmpty
    }
}

/// Mock pour GeocodingService
class MockGeocodingService: GeocodingService {
    var geocodeAddressCalled = false
    var mockCoordinates = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
    var mockError: Error?
    
    func geocodeAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        geocodeAddressCalled = true
        if let error = mockError {
            throw error
        }
        return mockCoordinates
    }
}

/// Mock pour MapNetworkService
class MockMapNetworkService: MapNetworkService {
    var getStaticMapURLCalled = false
    var mockMapURL = URL(string: "https://example.com/map.png")!
    var mockError: Error?
    
    func getStaticMapURL(for coordinates: CLLocationCoordinate2D, size: CGSize, zoom: Int) -> URL {
        getStaticMapURLCalled = true
        return mockMapURL
    }
}

/// Mock pour ConfigurationService
class MockConfigurationService: ConfigurationService {
    var getMapApiKeyCalled = false
    var mockApiKey = "mock_api_key"
    
    func getMapApiKey() -> String {
        getMapApiKeyCalled = true
        return mockApiKey
    }
}

/// Mock pour APIService
class MockAPIService: APIServiceProtocol {
    var requestCalled = false
    var requestDataCalled = false
    var uploadFileCalled = false
    var buildURLCalled = false
    
    var mockError: Error?
    var mockData = Data()
    var mockURL = URL(string: "https://example.com")!
    
    func request<T: Decodable>(url: URL, method: HTTPMethod, headers: [String: String]?, parameters: [String: Any]?, responseType: T.Type) async throws -> T {
        requestCalled = true
        if let error = mockError {
            throw error
        }
        
        // Créer un objet mockée du type demandé
        // Note: Cette approche fonctionne uniquement si T peut être initialisé à partir de JSON vide
        let decoder = JSONDecoder()
        do {
            return try decoder.decode(T.self, from: mockData)
        } catch {
            // Fallback pour les tests: créer un mock d'un autre type
            throw APIError.decodingError(error)
        }
    }
    
    func requestData(url: URL, method: HTTPMethod, headers: [String: String]?, parameters: [String: Any]?) async throws -> Data {
        requestDataCalled = true
        if let error = mockError {
            throw error
        }
        return mockData
    }
    
    func uploadFile(url: URL, method: HTTPMethod, headers: [String: String]?, parameters: [String: String]?, fileData: Data, fileName: String, mimeType: String, fileFieldName: String) async throws -> Data {
        uploadFileCalled = true
        if let error = mockError {
            throw error
        }
        return mockData
    }
    
    func buildURL(baseURL: URL, queryItems: [URLQueryItem]?) throws -> URL {
        buildURLCalled = true
        if let error = mockError {
            throw error
        }
        return mockURL
    }
}
