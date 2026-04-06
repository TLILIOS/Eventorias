
//
// EventViewModel.swift
// Eventorias
//
// Created by TLiLi Hamdi on 02/06/2025.
//

import Foundation
import SwiftUI
import PhotosUI
import Observation
import UIKit
import UserNotifications
// Pas besoin d'importer ImageUploadState car il est défini dans le même module

@Observable
class EventViewModel: EventViewModelProtocol {
    // Définition du type associé requis par le protocole
    typealias UploadStateType = ImageUploadState
    
    // MARK: - Published Properties
    var events: [Event] = []
    var isLoading = false
    var searchText = ""
    var errorMessage = ""
    var showingError = false
    var sortOption: SortOption = .dateAscending
    
    // Filtres et mode d'affichage
    var selectedCategory: EventCategory? = nil
    var dateRange: (Date, Date)? = nil
    var viewMode: ViewMode = .list
    
    // MARK: - Event Creation Properties
    var eventTitle = ""
    var eventDescription = ""
    var eventDate = Date()
    var eventAddress = ""
    var eventImage: UIImage? = nil
    var eventCreationSuccess = false
    var imageUploadState: ImageUploadState = .ready
    
    // MARK: - Private Properties
    private let eventService: EventServiceProtocol
    private let notificationService: NotificationServiceProtocol
    private var hasRequestedNotificationPermission = false
    private var hasScheduledNotifications = false

    // MARK: - Initialization
    init(eventService: EventServiceProtocol, notificationService: NotificationServiceProtocol) {
        self.eventService = eventService
        self.notificationService = notificationService
    }
    
    // MARK: - Notification Methods
    
    /// Demande l'autorisation d'envoyer des notifications à l'utilisateur (une seule fois)
    func requestNotificationPermission() {
        guard !hasRequestedNotificationPermission else { return }
        hasRequestedNotificationPermission = true

        notificationService.requestAuthorization { [weak self] granted in
            if granted {
                print("📱 Notifications autorisées par l'utilisateur")
                self?.scheduleNotificationsForEvents()
            } else {
                print("❌ L'utilisateur a refusé les notifications")
            }
        }
    }

    /// Planifie des notifications pour tous les événements à venir (une seule fois par chargement)
    func scheduleNotificationsForEvents() {
        guard !hasScheduledNotifications, !events.isEmpty else { return }
        hasScheduledNotifications = true

        notificationService.scheduleNotificationsForUpcomingEvents(events: events) { success in
            if success {
                print("✅ Notifications planifiées pour les événements à venir")
            } else {
                print("⚠️ Échec de la planification des notifications")
            }
        }
    }
    
    /// Planifie une notification pour un événement spécifique
    /// - Parameter event: L'événement pour lequel planifier une notification
    func scheduleNotificationForEvent(_ event: Event) {
        notificationService.scheduleEventNotification(for: event, timeInterval: 24 * 60 * 60) { success in
            if success {
                print("✅ Notification planifiée pour l'événement: \(event.title)")
            } else {
                print("⚠️ Échec de la planification de la notification pour l'événement: \(event.title)")
            }
        }
    }
    
    /// Annule toutes les notifications planifiées
    func cancelAllNotifications() {
        notificationService.cancelAllNotifications()
        print("🗑️ Toutes les notifications ont été annulées")
    }
    
    // MARK: - Enums
    enum SortOption: String, CaseIterable, Identifiable {
        case dateAscending = "Date (croissant)"
        case dateDescending = "Date (décroissant)"
        var id: String { self.rawValue }
    }
    
    enum ViewMode {
        case list
        case calendar
    }
    
    // MARK: - Private Methods
    private func filterEventsBySearch() -> [Event] {
        let query = searchText.lowercased()
        return events.filter { event in
            event.title.lowercased().contains(query) ||
            event.description.lowercased().contains(query) ||
            event.location.lowercased().contains(query)
        }
    }
    
    private func sortEventsByOption(_ events: [Event]) -> [Event] {
        switch sortOption {
        case .dateAscending:
            return events.sorted { $0.date < $1.date }
        case .dateDescending:
            return events.sorted { $0.date > $1.date }
        }
    }

    
    private func performAction(_ action: () async throws -> Void) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await action()
        } catch {
            handleError(error)
        }
    }
    
    private func fetchSortedEventsFromService() async throws -> [Event] {
        let ascending = sortOption == .dateAscending
        return try await eventService.getEventsSortedByDate(ascending: ascending)
    }
    
    private func ensureSampleEventsExist() async throws {
        let isEmpty = try await eventService.isEventsCollectionEmpty()
        if isEmpty {
            try await eventService.addSampleEvents()
        }
    }
    
    private func validateEventCreationData() throws {
        guard !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyTitle
        }
        
        guard !eventAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.emptyAddress
        }
    }
    
    // MARK: - Computed Properties
    var filteredEvents: [Event] {
        // Filtrage par texte
        var filtered = searchText.isEmpty ? events : filterEventsBySearch()
        
        // Filtrage par catégorie
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // Filtrage par date
        if let (start, end) = dateRange {
            filtered = filtered.filter { event in
                return event.date >= start && event.date <= end
            }
        }
        
        // Tri final
        return sortEventsByOption(filtered)
    }
    
    // Indique si des filtres sont actifs
    var hasActiveFilters: Bool {
        return selectedCategory != nil || dateRange != nil
    }
    
    // Indique si un filtre de date est actif
    var hasDateFilter: Bool {
        return dateRange != nil
    }
    
    // MARK: - Public Methods
    func fetchEvents() async {
        await performAction {
            try await ensureSampleEventsExist()
            events = try await fetchSortedEventsFromService()
        }

        // Planifier les notifications une seule fois après le premier chargement réussi
        if !events.isEmpty {
            scheduleNotificationsForEvents()
            requestNotificationPermission()
        }
    }
    
    // Change le mode d'affichage (liste/calendrier)
    func toggleViewMode() {
        viewMode = viewMode == .list ? .calendar : .list
    }
    
    // Réinitialise tous les filtres
    func resetAllFilters() {
        selectedCategory = nil
        dateRange = nil
    }
    
    func refreshEvents() async {
        await fetchEvents()
    }
    
    func updateSortOption(_ newOption: SortOption) async {
        sortOption = newOption
        await performAction {
            events = try await fetchSortedEventsFromService()
        }
    }
    
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    @discardableResult
    /// Crée un nouvel événement avec les données actuelles
    /// - Returns: true si la création a réussi, false sinon
    func createEvent() async -> Bool {
        // Réinitialiser l'état d'erreur
        showingError = false
        errorMessage = ""
        
        do {
            // Validation des données
            try validateEventCreationData()
            
            // Marquer le début du chargement
            isLoading = true
            
            // Upload de l'image si présente
            let imageURL = try await uploadEventImage()
            
            // Création de l'événement
            let eventId = try await eventService.createEvent(
                title: eventTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: eventDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                    "Pas de description" : eventDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                date: eventDate,
                location: eventAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                imageURL: imageURL
            )
            
            // CORRECTION CRUCIALE: Marquer le succès
            eventCreationSuccess = true
            isLoading = false
            
            // Recharger les événements et réinitialiser
            await fetchEvents()
            
            // Planifier une notification pour le nouvel événement
            if let newEvent = events.first(where: { $0.id == eventId }) {
                scheduleNotificationForEvent(newEvent)
            }
            
            resetEventFormFields()
            
            return true
            
        } catch {
            // Gestion des erreurs
            handleError(error)
            eventCreationSuccess = false
            isLoading = false
            return false
        }
    }

    /// Upload une image vers Firebase Storage
     func uploadEventImage() async throws -> String? {
        guard let image = eventImage else {
            return nil
        }
        
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw ValidationError.imageConversionFailed
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

    /// Gère les erreurs
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showingError = true
    }

    
    func resetEventFormFields() {
        eventTitle = ""
        eventDescription = ""
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .ready
    }
}

// MARK: - Validation Errors
extension EventViewModel {
    enum ValidationError: LocalizedError {
        case emptyTitle
        case emptyAddress
        case imageConversionFailed
        
        var errorDescription: String? {
            switch self {
            case .emptyTitle:
                return "Le titre de l'événement ne peut pas être vide"
            case .emptyAddress:
                return "L'adresse de l'événement ne peut pas être vide"
            case .imageConversionFailed:
                return "Impossible de convertir l'image"
            }
        }
    }
}

// MARK: - Convenience Methods
extension EventViewModel {
    var isFormValid: Bool {
        !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !eventAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var hasEvents: Bool {
        !filteredEvents.isEmpty
    }
    
    var isSearchActive: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var emptyStateMessage: String {
        if isSearchActive {
            return "Aucun résultat pour \"\(searchText)\""
        } else {
            return "Aucun événement disponible"
        }
    }
}
