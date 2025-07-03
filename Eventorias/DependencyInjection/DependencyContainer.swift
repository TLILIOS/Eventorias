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
    
    /// Returns NotificationService implementation
    func notificationService() -> NotificationServiceProtocol
}

/// Default implementation of the dependency container for the main application
class AppDependencyContainer: DependencyContainerProtocol {
    /// Singleton instance for app-wide access
    static let shared = AppDependencyContainer()
    
    // Cache des services pour éviter de créer plusieurs instances
    private var apiServiceInstance: APIServiceProtocol?
    private var authServiceInstance: AuthenticationServiceProtocol?
    private var keychainServiceInstance: KeychainServiceProtocol?
    private var storageServiceInstance: StorageServiceProtocol?
    private var firestoreServiceInstance: FirestoreServiceProtocol?
    private var notificationServiceInstance: NotificationServiceProtocol?
    private var authViewModelInstance: AuthenticationViewModel?
    
    /// Private initializer to enforce singleton pattern
    private init() {}
    
    /// Returns the concrete implementation of EventService
    func eventService() -> EventServiceProtocol {
        return EventService()
    }
    
    /// Returns the concrete implementation of FirestoreService
    func firestoreService() -> FirestoreServiceProtocol {
        if let existingService = firestoreServiceInstance {
            return existingService
        }
        let newService = DefaultEventFirestoreService()
        firestoreServiceInstance = newService
        return newService
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
        if let existingService = authServiceInstance {
            return existingService
        }
        let newService = FirebaseAuthenticationService()
        authServiceInstance = newService
        return newService
    }
    
    /// Returns the concrete implementation of KeychainService
    func keychainService() -> KeychainServiceProtocol {
        if let existingService = keychainServiceInstance {
            return existingService
        }
        let newService = KeychainService()
        keychainServiceInstance = newService
        return newService
    }
    
    /// Returns the concrete implementation of StorageService
    func storageService() -> StorageServiceProtocol {
        if let existingService = storageServiceInstance {
            return existingService
        }
        let newService = FirebaseStorageService()
        storageServiceInstance = newService
        return newService
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
    
    /// Returns the concrete implementation of NotificationService
    func notificationService() -> NotificationServiceProtocol {
        if let existingService = notificationServiceInstance {
            return existingService
        }
        let newService = NotificationService()
        notificationServiceInstance = newService
        return newService
    }
    
    /// Redéfinition de la méthode pour utiliser le singleton AuthenticationViewModel
    func makeAuthenticationViewModel() -> AuthenticationViewModel {
        if let existingViewModel = authViewModelInstance {
            return existingViewModel
        }
        
        let newViewModel = AuthenticationViewModel(
            authService: authenticationService(),
            keychainService: keychainService(),
            storageService: storageService()
        )
        authViewModelInstance = newViewModel
        return newViewModel
    }
}

/// Removes the necessity for repetitive container instance passing
extension DependencyContainerProtocol {
    /// Creates and configures an EventViewModel with the container's event service
    func makeEventViewModel() -> EventViewModel {
        return EventViewModel(eventService: eventService(), notificationService: notificationService())
    }
    
    /// Creates and configures an EventDetailsViewModel with the container's services
    func makeEventDetailsViewModel() -> EventDetailsViewModel {
        return EventDetailsViewModel(
            firestoreService: firestoreService(),
            geocodingService: geocodingService(),
            mapNetworkService: mapNetworkService(),
            configurationService: configurationService(),
            authenticationService: authenticationService()
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
    func makeEventCreationViewModel(eventViewModel: any EventViewModelProtocol) -> EventCreationViewModel {
        // Wrapping du EventViewModelProtocol avec notre type-erased wrapper
        let anyEventViewModel = AnyEventViewModel(eventViewModel)
        
        return EventCreationViewModel(
            eventViewModel: anyEventViewModel,
            authService: authenticationService(),
            storageService: storageService(),
            firestoreService: firestoreService() 
        )
    }
    
    /// Creates and configures an InvitationViewModel with the container's services
    func makeInvitationViewModel() -> InvitationViewModel {
        return InvitationViewModel(
            firestoreService: firestoreService(), 
            authService: authenticationService()
        )
    }
    
    // Add other view model factories as needed
}
