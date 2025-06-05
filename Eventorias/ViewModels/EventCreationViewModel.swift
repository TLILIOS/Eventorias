//
//  EventCreationViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import Combine

/// ViewModel responsable de la gestion de la création d'événements
@MainActor
final class EventCreationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Form values
    @Published var eventTitle: String = "New event"
    @Published var eventDescription: String = "Tap here to enter your description"
    @Published var eventDate: Date = Date()
    @Published var eventAddress: String = ""
    @Published var eventImage: UIImage?
    
    // UI state
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var imageUploadState: ImageUploadState = .idle
    @Published var eventCreationSuccess = false
    @Published var errorMessage = ""
    
    // MARK: - Dependencies
    
    private let eventViewModel: EventViewModel
    
    // MARK: - Initialization
    
    init(eventViewModel: EventViewModel) {
        self.eventViewModel = eventViewModel
    }
    
    // MARK: - Image Upload State
    
    enum ImageUploadState: Equatable {
        case idle
        case uploading(Double)
        case success
        case failure
        
        static func ==(lhs: ImageUploadState, rhs: ImageUploadState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.success, .success), (.failure, .failure):
                return true
            case (.uploading(let lhsProgress), .uploading(let rhsProgress)):
                return lhsProgress == rhsProgress
            default:
                return false
            }
        }
    }
    
    // MARK: - Methods
    
    /// Crée un nouvel événement avec les valeurs actuelles
    /// - Returns: Un booléen indiquant si la création a réussi
    @MainActor
    func createEvent() async -> Bool {
        // Transférer les valeurs au eventViewModel
        eventViewModel.eventTitle = eventTitle
        eventViewModel.eventDescription = eventDescription
        eventViewModel.eventDate = eventDate
        eventViewModel.eventAddress = eventAddress
        eventViewModel.eventImage = eventImage
        
        // Créer l'événement
        await eventViewModel.createEvent()
        
        // Récupérer les résultats
        eventCreationSuccess = eventViewModel.eventCreationSuccess
        errorMessage = eventViewModel.errorMessage
        imageUploadState = mapImageUploadState(from: eventViewModel.imageUploadState)
        
        return eventCreationSuccess
    }
    
    /// Réinitialise les valeurs du formulaire
    func resetForm() {
        eventTitle = "New event"
        eventDescription = "Tap here to enter your description"
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .idle
        eventCreationSuccess = false
        errorMessage = ""
    }
    
    /// Mappe l'état d'upload de l'image depuis EventViewModel
    private func mapImageUploadState(from state: Any) -> ImageUploadState {
        // Imaginons que EventViewModel.imageUploadState est de type similaire
        // Cette fonction mappe simplement l'état depuis EventViewModel vers notre propre type
        return eventViewModel.imageUploadState as? ImageUploadState ?? .idle
    }
}
