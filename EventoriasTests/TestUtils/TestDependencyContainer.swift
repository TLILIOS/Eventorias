//
//  TestDependencyContainer.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation
@testable import Eventorias

/// Dependency container implementation for testing
class TestDependencyContainer: DependencyContainerProtocol {
    /// Mock event service to be injected into test subjects
    private let mockEventService: MockEventService
    
    /// Mock implementations for other services
    private let mockFirestoreService: EventFirestoreService = MockEventFirestoreService()
    private let mockGeocodingService: GeocodingService = MockGeocodingService()
    private let mockMapNetworkService: MapNetworkService = MockMapNetworkService()
    private let mockConfigurationService: ConfigurationService = MockConfigurationService()
    
    /// Standard initializer with default mock service
    init(mockEventService: MockEventService = MockEventService()) {
        self.mockEventService = mockEventService
    }
    
    /// Returns the configured mock event service
    func eventService() -> EventServiceProtocol {
        return mockEventService
    }
    
    /// Returns mock firestore service
    func firestoreService() -> EventFirestoreService {
        return mockFirestoreService
    }
    
    /// Returns mock geocoding service
    func geocodingService() -> GeocodingService {
        return mockGeocodingService
    }
    
    /// Returns mock map network service
    func mapNetworkService() -> MapNetworkService {
        return mockMapNetworkService
    }
    
    /// Returns mock configuration service
    func configurationService() -> ConfigurationService {
        return mockConfigurationService
    }
    
    /// Convenience method to directly access the mock for test setup
    func getMockEventService() -> MockEventService {
        return mockEventService
    }
    
    // Add other mock service access methods as needed
}
