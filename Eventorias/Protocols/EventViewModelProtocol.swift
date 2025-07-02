// 
// EventViewModelProtocol.swift
// Eventorias
//
// Created on 13/06/2025.
//

import Foundation
import SwiftUI
import Combine
import UIKit

// Assurons-nous que l'énumération est accessible
import Eventorias

/// Protocole définissant les fonctionnalités requises d'un EventViewModel
protocol EventViewModelProtocol: ObservableObject {
    // MARK: - Associated Types
    
    /// Type pour l'état d'upload de l'image
    associatedtype UploadStateType: Equatable
    
    // MARK: - Event Creation Properties
    
    /// Titre de l'événement
    var eventTitle: String { get set }
    
    /// Description de l'événement
    var eventDescription: String { get set }
    
    /// Date de l'événement
    var eventDate: Date { get set }
    
    /// Adresse de l'événement
    var eventAddress: String { get set }
    
    /// Image sélectionnée pour l'événement
    var eventImage: UIImage? { get set }
    
    /// État d'upload de l'image
    var imageUploadState: UploadStateType { get set }
    
    // MARK: - Methods
    
    /// Crée un nouvel événement avec les informations actuelles
    /// - Returns: true si la création a réussi, false sinon
    @discardableResult
    func createEvent() async -> Bool
}
