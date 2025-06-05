//
//  EventViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 02/06/2025.
//

import Foundation
import SwiftUI
import Combine
import UIKit
import PhotosUI

@MainActor
final class EventViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Liste des événements
    @Published var events: [Event] = []
    
    /// État de chargement
    @Published var isLoading = false
    
    /// Texte de recherche
    @Published var searchText = ""
    
    /// Message d'erreur
    @Published var errorMessage = ""
    
    /// Contrôle l'affichage de l'erreur
    @Published var showingError = false
    
    /// Option de tri sélectionnée
    @Published var sortOption: SortOption = .dateAscending
    
    // MARK: - Event Creation Properties
    
    /// Titre de l'événement
    @Published var eventTitle = ""
    
    /// Description de l'événement
    @Published var eventDescription = ""
    
    /// Date de l'événement
    @Published var eventDate = Date()
    
    /// Adresse de l'événement
    @Published var eventAddress = ""
    
    /// Image sélectionnée pour l'événement
    @Published var eventImage: UIImage? = nil
    
    /// Indique si la création de l'événement a réussi
    @Published var eventCreationSuccess = false
    
    /// État de l'upload d'image
    @Published var imageUploadState: ImageUploadState = .ready
    
    // MARK: - Enums
    
    enum SortOption: String, CaseIterable, Identifiable {
        case dateAscending = "Date (croissant)"
        case dateDescending = "Date (décroissant)"
        
        var id: String { self.rawValue }
    }
    
    enum ImageUploadState: Equatable {
        case ready
        case uploading(progress: Double)
        case success(url: String)
        case failure(error: String)
        
        var isUploading: Bool {
            switch self {
            case .uploading: return true
            default: return false
            }
        }
        
        var progressValue: Double {
            switch self {
            case .uploading(let progress): return progress
            case .success: return 1.0
            default: return 0.0
            }
        }
    }
    
    // MARK: - Private Properties
    
    /// Service des événements
    private let eventService: EventService
    
    /// Cancellables pour la gestion des abonnements
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    
    /// Événements filtrés selon le texte de recherche
    var filteredEvents: [Event] {
        if searchText.isEmpty {
            return events
        } else {
            let query = searchText.lowercased()
            return events.filter { event in
                let titleMatch = event.title.lowercased().contains(query)
                let descMatch = event.description.lowercased().contains(query)
                let locMatch = event.location.lowercased().contains(query)
                return titleMatch || descMatch || locMatch
            }
        }
    }
    
    // MARK: - Initialization
    
    init(eventService: EventService = EventService()) {
        self.eventService = eventService
        setupSearchSubscription()
        setupSortSubscription()
    }
    
    // MARK: - Private Methods
    
    /// Configure l'abonnement pour la recherche - utilise uniquement le filtrage local
    private func setupSearchSubscription() {
        // Désactivation des appels réseau pour la recherche
        // Nous utilisons uniquement la propriété filteredEvents pour le filtrage local
        $searchText
            .removeDuplicates()
            .sink { [weak self] query in
                print("📱 EventViewModel: Recherche locale pour: \(query)")
                // On déclenche une notification de changement de la liste filtrée
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Configure l'abonnement pour le tri
    private func setupSortSubscription() {
        $sortOption
            .dropFirst() // Ignorer la valeur initiale
            .sink { [weak self] _ in
                Task {
                    await self?.sortEvents()
                }
            }
            .store(in: &cancellables)
    }
    
    /// Gère les erreurs
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }
    
    /// Exécute une action avec gestion du loading
    private func performAction(_ action: () async throws -> Void) async {
        defer { isLoading = false }
        
        isLoading = true
        
        do {
            try await action()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Public Methods
    
    /// Récupère tous les événements
    func fetchEvents() async {
        await performAction {
            print("📱 EventViewModel: Début du chargement des événements...")
            
            // Vérifier si la collection d'événements est vide
            print("📱 EventViewModel: Vérification si la collection est vide...")
            let isEmpty = try await eventService.isEventsCollectionEmpty()
            print("📱 EventViewModel: Collection vide? \(isEmpty)")
            
            // Si vide, ajouter des exemples d'événements
            if isEmpty {
                print("📱 EventViewModel: Ajout d'événements d'exemple...")
                try await eventService.addSampleEvents()
                print("📱 EventViewModel: Événements d'exemple ajoutés avec succès")
            }
            
            // Récupérer les événements triés selon l'option actuelle
            print("📱 EventViewModel: Récupération des événements triés...")
            let sortedEvents = try await getSortedEvents()
            print("📱 EventViewModel: \(sortedEvents.count) événements récupérés")
            
            events = sortedEvents
            print("📱 EventViewModel: \(events.count) événements assignés au modèle")
        }
    }
    
    /// Recherche des événements basés sur une requête - seulement pour référence
    /// Cette méthode n'est plus utilisée car nous utilisons le filtrage local via filteredEvents
    func searchEvents(query: String) async {
        print("⚠️ searchEvents() appelée, mais cette méthode est désactivée en faveur du filtrage local")
        // Pas d'appel réseau, nous utilisons le filtrage local uniquement
    }
    
    /// Trie les événements selon l'option sélectionnée
    @discardableResult
    func sortEvents() async -> [Event] {
        defer { isLoading = false }
        
        isLoading = true
        
        do {
            events = try await getSortedEvents()
            return events
        } catch {
            handleError(error)
            return events
        }
    }
    
    /// Récupère les événements triés
    private func getSortedEvents() async throws -> [Event] {
        let ascending = sortOption == .dateAscending
        return try await eventService.getEventsSortedByDate(ascending: ascending)
    }
    
    /// Rafraîchit les événements
    func refreshEvents() async {
        await fetchEvents()
    }
    
    /// Ferme l'alerte d'erreur
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    /// Nettoie les ressources
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Event Creation Methods
    
    /// Crée un nouvel événement avec les données actuelles
    func createEvent() async {
        await performAction {
            print("📱 EventViewModel: Début de la création d'événement")
            guard !eventTitle.isEmpty else { 
                print("📱 EventViewModel: Erreur - titre vide")
                throw NSError(domain: "EventViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Le titre ne peut pas être vide"]) 
            }
            guard !eventAddress.isEmpty else { 
                print("📱 EventViewModel: Erreur - adresse vide")
                throw NSError(domain: "EventViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "L'adresse ne peut pas être vide"]) 
            }
            
            var imageURL: String? = nil
            
            // Si une image est fournie, l'uploader sur Firebase Storage
            if let image = eventImage, let imageData = image.jpegData(compressionQuality: 0.9) {
                print("📱 EventViewModel: Début de l'upload d'image (\(imageData.count) octets)")
                self.imageUploadState = .uploading(progress: 0.2)
                
                do {
                    // Simuler une progression réaliste pour l'interface utilisateur
                    self.imageUploadState = .uploading(progress: 0.5)
                    
                    print("📱 EventViewModel: Tentative d'upload d'image vers Firebase Storage...")
                    imageURL = try await eventService.uploadImage(imageData: imageData)
                    print("📱 EventViewModel: Image uploadée avec succès: \(imageURL ?? "URL vide")")
                    self.imageUploadState = .success(url: imageURL ?? "")
                } catch {
                    print("📱 EventViewModel: Échec de l'upload d'image: \(error.localizedDescription)")
                    self.imageUploadState = .failure(error: error.localizedDescription)
                    throw error
                }
            } else {
                print("📱 EventViewModel: Pas d'image à uploader")
            }
            
            // Créer l'événement avec ou sans URL d'image
            print("📱 EventViewModel: Création de l'événement dans Firestore...")
            let eventId = try await eventService.createEvent(
                title: eventTitle,
                description: eventDescription.isEmpty ? "Pas de description" : eventDescription,
                date: eventDate,
                location: eventAddress,
                image: eventImage
            )
            print("📱 EventViewModel: Événement créé avec succès, ID: \(eventId)")
            
            // Réinitialiser les champs après la création réussie
            resetEventFormFields()
            
            // Marquer la création comme réussie pour afficher un message de confirmation
            eventCreationSuccess = true
            
            // Rafraîchir la liste des événements
            print("📱 EventViewModel: Actualisation de la liste des événements...")
            await fetchEvents()
        }
    }
    
    /// Réinitialise les champs du formulaire de création d'événement
    func resetEventFormFields() {
        eventTitle = ""
        eventDescription = ""
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .ready
    }
}
