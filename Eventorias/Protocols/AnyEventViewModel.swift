//
// AnyEventViewModel.swift
// Eventorias
//
// Created on 02/07/2025.
//

import Foundation
import UIKit
import SwiftUI

/// Type-erased wrapper autour de EventViewModelProtocol
/// Permet d'utiliser le protocole comme type existentiel malgré son associatedtype
@MainActor
final class AnyEventViewModel: ObservableObject {
    // MARK: - Event Creation Properties
    
    private let _getEventTitle: () -> String
    private let _setEventTitle: (String) -> Void
    
    private let _getEventDescription: () -> String
    private let _setEventDescription: (String) -> Void
    
    private let _getEventDate: () -> Date
    private let _setEventDate: (Date) -> Void
    
    private let _getEventAddress: () -> String
    private let _setEventAddress: (String) -> Void
    
    private let _getEventImage: () -> UIImage?
    private let _setEventImage: (UIImage?) -> Void
    
    private let _getImageUploadState: () -> Any
    private let _setImageUploadState: (Any) -> Void
    
    private let _createEvent: () async -> Bool
    
    // MARK: - Public interface
    
    var eventTitle: String {
        get { _getEventTitle() }
        set { _setEventTitle(newValue) }
    }
    
    var eventDescription: String {
        get { _getEventDescription() }
        set { _setEventDescription(newValue) }
    }
    
    var eventDate: Date {
        get { _getEventDate() }
        set { _setEventDate(newValue) }
    }
    
    var eventAddress: String {
        get { _getEventAddress() }
        set { _setEventAddress(newValue) }
    }
    
    var eventImage: UIImage? {
        get { _getEventImage() }
        set { _setEventImage(newValue) }
    }
    
    // Propriété spécifique au type
    var imageUploadState: ImageUploadState {
        get { 
            // Conversion sécurisée du type associé vers ImageUploadState
            if let state = _getImageUploadState() as? ImageUploadState {
                return state
            }
            // Valeur par défaut si la conversion échoue
            return .ready
        }
        set { _setImageUploadState(newValue) }
    }
    
    // MARK: - Methods
    
    @discardableResult
    func createEvent() async -> Bool {
        await _createEvent()
    }
    
    // MARK: - Initialization
    
    /// Initialise avec un modèle concret qui respecte EventViewModelProtocol
    init<ViewModel: EventViewModelProtocol>(_ viewModel: ViewModel) {
        _getEventTitle = { viewModel.eventTitle }
        _setEventTitle = { viewModel.eventTitle = $0 }
        
        _getEventDescription = { viewModel.eventDescription }
        _setEventDescription = { viewModel.eventDescription = $0 }
        
        _getEventDate = { viewModel.eventDate }
        _setEventDate = { viewModel.eventDate = $0 }
        
        _getEventAddress = { viewModel.eventAddress }
        _setEventAddress = { viewModel.eventAddress = $0 }
        
        _getEventImage = { viewModel.eventImage }
        _setEventImage = { viewModel.eventImage = $0 }
        
        _getImageUploadState = { viewModel.imageUploadState }
        _setImageUploadState = { 
            if let typedValue = $0 as? ViewModel.UploadStateType {
                viewModel.imageUploadState = typedValue
            }
        }
        
        _createEvent = { await viewModel.createEvent() }
    }
}
