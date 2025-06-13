////
////  EventViewModel.swift
////  Eventorias
////
////  Created by TLiLi Hamdi on 02/06/2025.
////
//
//import Foundation
//import SwiftUI
//import Combine
//import PhotosUI
//
//@MainActor
//final class EventViewModel: ObservableObject {
//    // MARK: - Published Properties
//    
//    /// Liste des événements
//    @Published var events: [Event] = []
//    
//    /// État de chargement
//    @Published var isLoading = false
//    
//    /// Texte de recherche
//    @Published var searchText = ""
//    
//    /// Message d'erreur
//    @Published var errorMessage = ""
//    
//    /// Contrôle l'affichage de l'erreur
//    @Published var showingError = false
//    
//    /// Option de tri sélectionnée
//    @Published var sortOption: SortOption = .dateAscending
//    
//    // MARK: - Event Creation Properties
//    
//    /// Titre de l'événement
//    @Published var eventTitle = ""
//    
//    /// Description de l'événement
//    @Published var eventDescription = ""
//    
//    /// Date de l'événement
//    @Published var eventDate = Date()
//    
//    /// Adresse de l'événement
//    @Published var eventAddress = ""
//    
//    /// Image sélectionnée pour l'événement
//    @Published var eventImage: UIImage? = nil
//    
//    /// Indique si la création de l'événement a réussi
//    @Published var eventCreationSuccess = false
//    
//    /// État de l'upload d'image
//    @Published var imageUploadState: ImageUploadState = .ready
//    
//    // MARK: - Enums
//    
//    enum SortOption: String, CaseIterable, Identifiable {
//        case dateAscending = "Date (croissant)"
//        case dateDescending = "Date (décroissant)"
//        
//        var id: String { self.rawValue }
//    }
//    
//    enum ImageUploadState: Equatable {
//        case ready
//        case uploading(progress: Double)
//        case success(url: String)
//        case failure(error: String)
//        
//        var isUploading: Bool {
//            switch self {
//            case .uploading: return true
//            default: return false
//            }
//        }
//        
//        var progressValue: Double {
//            switch self {
//            case .uploading(let progress): return progress
//            case .success: return 1.0
//            default: return 0.0
//            }
//        }
//    }
//    
//    // MARK: - Private Properties
//    
//    /// Service des événements
//    private let eventService: EventService
//    
//    /// Cancellables pour la gestion des abonnements
//    private var cancellables = Set<AnyCancellable>()
//    
//    // MARK: - Computed Properties
//    
//    /// Événements filtrés selon le texte de recherche
//    var filteredEvents: [Event] {
//        if searchText.isEmpty {
//            return events
//        } else {
//            let query = searchText.lowercased()
//            return events.filter { event in
//                let titleMatch = event.title.lowercased().contains(query)
//                let descMatch = event.description.lowercased().contains(query)
//                let locMatch = event.location.lowercased().contains(query)
//                return titleMatch || descMatch || locMatch
//            }
//        }
//    }
//    
//    // MARK: - Initialization
//    
//    init(eventService: EventService = EventService()) {
//        self.eventService = eventService
//        setupSearchSubscription()
//        setupSortSubscription()
//    }
//    
//    // MARK: - Private Methods
//    
//    /// Configure l'abonnement pour la recherche - utilise uniquement le filtrage local
//    private func setupSearchSubscription() {
//        // Désactivation des appels réseau pour la recherche
//        // Nous utilisons uniquement la propriété filteredEvents pour le filtrage local
//        $searchText
//            .removeDuplicates()
//            .sink { [weak self] query in
//                print("📱 EventViewModel: Recherche locale pour: \(query)")
//                // On déclenche une notification de changement de la liste filtrée
//                self?.objectWillChange.send()
//            }
//            .store(in: &cancellables)
//    }
//    
//    /// Configure l'abonnement pour le tri
//    private func setupSortSubscription() {
//        $sortOption
//            .dropFirst() // Ignorer la valeur initiale
//            .sink { [weak self] _ in
//                Task {
//                    await self?.sortEvents()
//                }
//            }
//            .store(in: &cancellables)
//    }
//    
//    /// Gère les erreurs
//    private func handleError(_ error: Error) {
//        errorMessage = error.localizedDescription
//        showingError = true
//    }
//    
//    /// Exécute une action avec gestion du loading
//    private func performAction(_ action: () async throws -> Void) async {
//        defer { isLoading = false }
//        
//        isLoading = true
//        
//        do {
//            try await action()
//        } catch {
//            handleError(error)
//        }
//    }
//    
//    // MARK: - Public Methods
//    
//    /// Récupère tous les événements
//    func fetchEvents() async {
//        await performAction {
//            print("📱 EventViewModel: Début du chargement des événements...")
//            
//            // Vérifier si la collection d'événements est vide
//            print("📱 EventViewModel: Vérification si la collection est vide...")
//            let isEmpty = try await eventService.isEventsCollectionEmpty()
//            print("📱 EventViewModel: Collection vide? \(isEmpty)")
//            
//            // Si vide, ajouter des exemples d'événements
//            if isEmpty {
//                print("📱 EventViewModel: Ajout d'événements d'exemple...")
//                try await eventService.addSampleEvents()
//                print("📱 EventViewModel: Événements d'exemple ajoutés avec succès")
//            }
//            
//            // Récupérer les événements triés selon l'option actuelle
//            print("📱 EventViewModel: Récupération des événements triés...")
//            let sortedEvents = try await getSortedEvents()
//            print("📱 EventViewModel: \(sortedEvents.count) événements récupérés")
//            
//            events = sortedEvents
//            print("📱 EventViewModel: \(events.count) événements assignés au modèle")
//        }
//    }
//    
//    /// Recherche des événements basés sur une requête - seulement pour référence
//    /// Cette méthode n'est plus utilisée car nous utilisons le filtrage local via filteredEvents
//    func searchEvents(query: String) async {
//        print("⚠️ searchEvents() appelée, mais cette méthode est désactivée en faveur du filtrage local")
//        // Pas d'appel réseau, nous utilisons le filtrage local uniquement
//    }
//    
//    /// Trie les événements selon l'option sélectionnée
//    @discardableResult
//    func sortEvents() async -> [Event] {
//        defer { isLoading = false }
//        
//        isLoading = true
//        
//        do {
//            events = try await getSortedEvents()
//            return events
//        } catch {
//            handleError(error)
//            return events
//        }
//    }
//    
//    /// Récupère les événements triés
//    private func getSortedEvents() async throws -> [Event] {
//        let ascending = sortOption == .dateAscending
//        return try await eventService.getEventsSortedByDate(ascending: ascending)
//    }
//    
//    /// Rafraîchit les événements
//    func refreshEvents() async {
//        await fetchEvents()
//    }
//    
//    /// Ferme l'alerte d'erreur
//    func dismissError() {
//        showingError = false
//        errorMessage = ""
//    }
//    
//    /// Nettoie les ressources
//    deinit {
//        cancellables.removeAll()
//    }
//    
//    // MARK: - Event Creation Methods
//    
//    /// Crée un nouvel événement avec les données actuelles
//    func createEvent() async {
//        await performAction {
//            print("📱 EventViewModel: Début de la création d'événement")
//            guard !eventTitle.isEmpty else { 
//                print("📱 EventViewModel: Erreur - titre vide")
//                throw NSError(domain: "EventViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "Le titre ne peut pas être vide"]) 
//            }
//            guard !eventAddress.isEmpty else { 
//                print("📱 EventViewModel: Erreur - adresse vide")
//                throw NSError(domain: "EventViewModel", code: 400, userInfo: [NSLocalizedDescriptionKey: "L'adresse ne peut pas être vide"]) 
//            }
//            
//            var imageURL: String? = nil
//            
//            // Si une image est fournie, l'uploader sur Firebase Storage
//            if let image = eventImage, let imageData = image.jpegData(compressionQuality: 0.9) {
//                print("📱 EventViewModel: Début de l'upload d'image (\(imageData.count) octets)")
//                self.imageUploadState = .uploading(progress: 0.2)
//                
//                do {
//                    // Simuler une progression réaliste pour l'interface utilisateur
//                    self.imageUploadState = .uploading(progress: 0.5)
//                    
//                    print("📱 EventViewModel: Tentative d'upload d'image vers Firebase Storage...")
//                    imageURL = try await eventService.uploadImage(imageData: imageData)
//                    print("📱 EventViewModel: Image uploadée avec succès: \(imageURL ?? "URL vide")")
//                    self.imageUploadState = .success(url: imageURL ?? "")
//                } catch {
//                    print("📱 EventViewModel: Échec de l'upload d'image: \(error.localizedDescription)")
//                    self.imageUploadState = .failure(error: error.localizedDescription)
//                    throw error
//                }
//            } else {
//                print("📱 EventViewModel: Pas d'image à uploader")
//            }
//            
//            // Créer l'événement avec ou sans URL d'image
//            print("📱 EventViewModel: Création de l'événement dans Firestore...")
//            let eventId = try await eventService.createEvent(
//                title: eventTitle,
//                description: eventDescription.isEmpty ? "Pas de description" : eventDescription,
//                date: eventDate,
//                location: eventAddress,
//                image: eventImage
//            )
//            print("📱 EventViewModel: Événement créé avec succès, ID: \(eventId)")
//            
//            // Réinitialiser les champs après la création réussie
//            resetEventFormFields()
//            
//            // Marquer la création comme réussie pour afficher un message de confirmation
//            eventCreationSuccess = true
//            
//            // Rafraîchir la liste des événements
//            print("📱 EventViewModel: Actualisation de la liste des événements...")
//            await fetchEvents()
//        }
//    }
//    
//    /// Réinitialise les champs du formulaire de création d'événement
//    func resetEventFormFields() {
//        eventTitle = ""
//        eventDescription = ""
//        eventDate = Date()
//        eventAddress = ""
//        eventImage = nil
//        imageUploadState = .ready
//    }
//}

//
//  EventViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 02/06/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import Observation

@Observable
@MainActor
final class EventViewModel {
    // MARK: - Published Properties
    
    /// Liste des événements
    var events: [Event] = []
    
    /// État de chargement
    var isLoading = false
    
    /// Texte de recherche
    var searchText = ""
    
    /// Message d'erreur
    var errorMessage = ""
    
    /// Contrôle l'affichage de l'erreur
    var showingError = false
    
    /// Option de tri sélectionnée
    var sortOption: SortOption = .dateAscending
    
    // MARK: - Event Creation Properties
    
    /// Titre de l'événement
    var eventTitle = ""
    
    /// Description de l'événement
    var eventDescription = ""
    
    /// Date de l'événement
    var eventDate = Date()
    
    /// Adresse de l'événement
    var eventAddress = ""
    
    /// Image sélectionnée pour l'événement
    var eventImage: UIImage? = nil
    
    /// Indique si la création de l'événement a réussi
    var eventCreationSuccess = false
    
    /// État de l'upload d'image
    var imageUploadState: ImageUploadState = .ready
    
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
    
    // MARK: - Computed Properties
    
    /// Événements filtrés selon le texte de recherche et triés
    var filteredEvents: [Event] {
        let filtered = searchText.isEmpty ? events : filterEventsBySearch()
        return sortEventsByOption(filtered)
    }
    
    // MARK: - Initialization
    
    init(eventService: EventService = EventService()) {
        self.eventService = eventService
    }
    
    // MARK: - Private Methods
    
    /// Filtre les événements selon le texte de recherche
    private func filterEventsBySearch() -> [Event] {
        let query = searchText.lowercased()
        return events.filter { event in
            event.title.lowercased().contains(query) ||
            event.description.lowercased().contains(query) ||
            event.location.lowercased().contains(query)
        }
    }
    
    /// Trie les événements selon l'option sélectionnée
    private func sortEventsByOption(_ events: [Event]) -> [Event] {
        switch sortOption {
        case .dateAscending:
            return events.sorted { $0.date < $1.date }
        case .dateDescending:
            return events.sorted { $0.date > $1.date }
        }
    }
    
    /// Gère les erreurs
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
        isLoading = false
    }
    
    /// Exécute une action avec gestion du loading
    private func performAction(_ action: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await action()
        } catch {
            handleError(error)
        }
    }
    
    /// Récupère les événements triés depuis le service
    private func fetchSortedEventsFromService() async throws -> [Event] {
        let ascending = sortOption == .dateAscending
        return try await eventService.getEventsSortedByDate(ascending: ascending)
    }
    
    /// Vérifie et ajoute des événements d'exemple si nécessaire
    private func ensureSampleEventsExist() async throws {
        let isEmpty = try await eventService.isEventsCollectionEmpty()
        if isEmpty {
            try await eventService.addSampleEvents()
        }
    }
    
    /// Valide les données de création d'événement
    private func validateEventCreationData() throws {
        guard !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        guard !eventAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyAddress
        }
    }
    
    /// Upload une image vers Firebase Storage
    private func uploadEventImage() async throws -> String? {
        guard let image = eventImage,
              let imageData = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }
        
        imageUploadState = .uploading(progress: 0.3)
        
        do {
            imageUploadState = .uploading(progress: 0.7)
            let imageURL = try await eventService.uploadImage(imageData: imageData)
            imageUploadState = .success(url: imageURL)
            return imageURL
        } catch {
            imageUploadState = .failure(error: error.localizedDescription)
            throw error
        }
    }
    
    // MARK: - Public Methods
    
    /// Récupère tous les événements
    func fetchEvents() async {
        await performAction {
            try await ensureSampleEventsExist()
            events = try await fetchSortedEventsFromService()
        }
    }
    
    /// Rafraîchit les événements
    func refreshEvents() async {
        await fetchEvents()
    }
    
    /// Met à jour l'option de tri et recharge les événements
    func updateSortOption(_ newOption: SortOption) async {
        sortOption = newOption
        await performAction {
            events = try await fetchSortedEventsFromService()
        }
    }
    
    /// Ferme l'alerte d'erreur
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    /// Crée un nouvel événement avec les données actuelles
    func createEvent() async {
        await performAction {
            try validateEventCreationData()
            
            let imageURL = try await uploadEventImage()
            
            let eventId = try await eventService.createEvent(
                title: eventTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    "Pas de description" : eventDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                date: eventDate,
                location: eventAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                image: eventImage
            )
            
            resetEventFormFields()
            eventCreationSuccess = true
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
        eventCreationSuccess = false
    }
    
    // Plus besoin de deinit car plus de Combine à nettoyer
}

// MARK: - Validation Errors

extension EventViewModel {
    enum ValidationError: LocalizedError {
        case emptyTitle
        case emptyAddress
        
        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Le titre de l'événement ne peut pas être vide"
            case .emptyAddress:
                return "L'adresse de l'événement ne peut pas être vide"
            }
        }
    }
}

// MARK: - Convenience Methods

extension EventViewModel {
    /// Indique si le formulaire de création est valide
    var isFormValid: Bool {
        !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !eventAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Indique si des événements sont affichés
    var hasEvents: Bool {
        !filteredEvents.isEmpty
    }
    
    /// Indique si la recherche est active
    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// Message pour l'état vide
    var emptyStateMessage: String {
        if isSearchActive {
            return "Aucun résultat pour \"\(searchText)\""
        } else {
            return "Aucun événement disponible"
        }
    }
}
