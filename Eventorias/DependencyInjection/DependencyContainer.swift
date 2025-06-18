//
//  DependencyContainer.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation
@MainActor
/// Protocol defining the contract for dependency containers
protocol DependencyContainerProtocol {
    /// Returns an event service implementation
    func eventService() -> EventServiceProtocol
    
    /// Returns EventFirestoreService implementation
    func firestoreService() -> EventFirestoreService
    
    /// Returns GeocodingService implementation
    func geocodingService() -> GeocodingService
    
    /// Returns MapNetworkService implementation
    func mapNetworkService() -> MapNetworkService
    
    /// Returns ConfigurationService implementation
    func configurationService() -> ConfigurationService
    
    /// Returns any other service implementations as needed
    // func authenticationService() -> AuthenticationServiceProtocol
    // Add other services as needed for the application
}

/// Default implementation of the dependency container for the main application
class AppDependencyContainer: DependencyContainerProtocol {
    /// Singleton instance for app-wide access
    static let shared = AppDependencyContainer()
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Returns the concrete implementation of EventService
    func eventService() -> EventServiceProtocol {
        return EventService()
    }
    
    /// Returns the concrete implementation of EventFirestoreService
    func firestoreService() -> EventFirestoreService {
        return DefaultEventFirestoreService()
    }
    
    /// Returns the concrete implementation of GeocodingService
    func geocodingService() -> GeocodingService {
        return DefaultGeocodingService()
    }
    
    /// Returns the concrete implementation of MapNetworkService
    func mapNetworkService() -> MapNetworkService {
        return DefaultMapNetworkService()
    }
    
    /// Returns the concrete implementation of ConfigurationService
    func configurationService() -> ConfigurationService {
        return DefaultConfigurationService()
    }
    
    // Add other service providers as needed
}

/// Removes the necessity for repetitive container instance passing
extension DependencyContainerProtocol {
    /// Creates and configures an EventViewModel with the container's event service
    func makeEventViewModel() -> EventViewModel {
        return EventViewModel(eventService: eventService())
    }
    
    /// Creates and configures an EventDetailsViewModel with the container's services
    func makeEventDetailsViewModel() -> EventDetailsViewModel {
        return EventDetailsViewModel(
            firestoreService: firestoreService(),
            geocodingService: geocodingService(),
            mapNetworkService: mapNetworkService(),
            configurationService: configurationService()
        )
    }
    
    // Add other view model factories as needed
}
