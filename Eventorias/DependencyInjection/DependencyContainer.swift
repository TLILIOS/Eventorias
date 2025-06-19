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
    
    /// Returns FirestoreService implementation
    func firestoreService() -> FirestoreServiceProtocol
    
    /// Returns GeocodingService implementation
    func geocodingService() -> GeocodingService
    
    /// Returns MapNetworkService implementation
    func mapNetworkService() -> MapNetworkService
    
    /// Returns ConfigurationService implementation
    func configurationService() -> ConfigurationService
    
    /// Returns AuthenticationService implementation
    func authenticationService() -> AuthenticationServiceProtocol
    
    /// Returns KeychainService implementation
    func keychainService() -> KeychainServiceProtocol
    
    /// Returns StorageService implementation
    func storageService() -> StorageServiceProtocol
    
    /// Returns APIService implementation
    func apiService() -> APIServiceProtocol
}

/// Default implementation of the dependency container for the main application
class AppDependencyContainer: DependencyContainerProtocol {
    /// Singleton instance for app-wide access
    static let shared = AppDependencyContainer()
    
    // Cache des services pour éviter de créer plusieurs instances
    private var apiServiceInstance: APIServiceProtocol?
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Returns the concrete implementation of EventService
    func eventService() -> EventServiceProtocol {
        return EventService()
    }
    
    /// Returns the concrete implementation of FirestoreService
    func firestoreService() -> FirestoreServiceProtocol {
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
    
    /// Returns the concrete implementation of AuthenticationService
    func authenticationService() -> AuthenticationServiceProtocol {
        return FirebaseAuthenticationService()
    }
    
    /// Returns the concrete implementation of KeychainService
    func keychainService() -> KeychainServiceProtocol {
        return KeychainService()
    }
    
    /// Returns the concrete implementation of StorageService
    func storageService() -> StorageServiceProtocol {
        return FirebaseStorageService()
    }
    
    /// Returns the concrete implementation of APIService
    func apiService() -> APIServiceProtocol {
        if let existingService = apiServiceInstance {
            return existingService
        }
        let newService = DefaultAPIService()
        apiServiceInstance = newService
        return newService
    }
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
    
    /// Creates and configures an AuthenticationViewModel with the container's services
    func makeAuthenticationViewModel() -> AuthenticationViewModel {
        return AuthenticationViewModel(
            authService: authenticationService(),
            keychainService: keychainService(),
            storageService: storageService()
        )
    }
    
    /// Creates and configures a ProfileViewModel with the container's services
    func makeProfileViewModel() -> ProfileViewModel {
        return ProfileViewModel(
            authViewModel: makeAuthenticationViewModel(),
            authService: authenticationService(),
            storageService: storageService()
        )
    }
    
    /// Creates and configures an EventCreationViewModel with the container's services
    func makeEventCreationViewModel(eventViewModel: EventViewModelProtocol) -> EventCreationViewModel {
        return EventCreationViewModel(
            eventViewModel: eventViewModel,
            authService: authenticationService(),
            storageService: storageService(),
            firestoreService: firestoreService() as! FirestoreServiceProtocol
        )
    }
    
    // Add other view model factories as needed
}
