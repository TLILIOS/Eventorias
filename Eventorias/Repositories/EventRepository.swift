//
//  EventRepository.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseFirestore

// MARK: - Protocols

/// Protocole pour une source de données d'événement distante
protocol EventRemoteDataSourceProtocol: RemoteDataSourceProtocol {
    /// Récupère tous les événements depuis la source distante
    /// - Returns: Liste des événements
    /// - Throws: Erreur en cas de problème
    func fetchEvents() async throws -> [Event]
    
    /// Récupère un événement spécifique
    /// - Parameter id: Identifiant de l'événement
    /// - Returns: L'événement si trouvé
    /// - Throws: Erreur en cas de problème
    func fetchEvent(id: String) async throws -> Event?
    
    /// Crée un nouvel événement
    /// - Parameter event: Événement à créer
    /// - Returns: Identifiant du nouvel événement
    /// - Throws: Erreur en cas de problème
    func createEvent(_ event: Event) async throws -> String
    
    /// Met à jour un événement existant
    /// - Parameters:
    ///   - id: Identifiant de l'événement
    ///   - event: Nouvelles données de l'événement
    /// - Throws: Erreur en cas de problème
    func updateEvent(id: String, with event: Event) async throws
    
    /// Supprime un événement
    /// - Parameter id: Identifiant de l'événement à supprimer
    /// - Throws: Erreur en cas de problème
    func deleteEvent(id: String) async throws
    
    /// Récupère les événements triés par date
    /// - Parameter ascending: Tri ascendant ou descendant
    /// - Returns: Liste des événements triés
    /// - Throws: Erreur en cas de problème
    func fetchEventsSortedByDate(ascending: Bool) async throws -> [Event]
    
    /// Vérifie si la collection d'événements est vide
    /// - Returns: Vrai si la collection est vide
    /// - Throws: Erreur en cas de problème
    func isEventsCollectionEmpty() async throws -> Bool
    
    /// Ajoute des événements d'exemple
    /// - Throws: Erreur en cas de problème
    func addSampleEvents() async throws
    
    /// Télécharge l'image d'un événement
    /// - Parameter imageData: Données de l'image
    /// - Returns: URL de l'image téléchargée
    /// - Throws: Erreur en cas de problème
    func uploadEventImage(imageData: Data) async throws -> String
}

/// Protocole pour une source de données d'événement locale
protocol EventLocalDataSourceProtocol: LocalDataSourceProtocol {
    /// Récupère tous les événements depuis la source locale
    /// - Returns: Liste des événements
    /// - Throws: Erreur en cas de problème
    func getEvents() async throws -> [Event]
    
    /// Récupère un événement spécifique
    /// - Parameter id: Identifiant de l'événement
    /// - Returns: L'événement si trouvé
    /// - Throws: Erreur en cas de problème
    func getEvent(id: String) async throws -> Event?
    
    /// Sauvegarde un événement localement
    /// - Parameter event: Événement à sauvegarder
    /// - Throws: Erreur en cas de problème
    func saveEvent(_ event: Event) async throws
    
    /// Sauvegarde plusieurs événements localement
    /// - Parameter events: Événements à sauvegarder
    /// - Throws: Erreur en cas de problème
    func saveEvents(_ events: [Event]) async throws
    
    /// Supprime un événement local
    /// - Parameter id: Identifiant de l'événement à supprimer
    /// - Throws: Erreur en cas de problème
    func deleteEvent(id: String) async throws
    
    /// Supprime tous les événements locaux
    /// - Throws: Erreur en cas de problème
    func clearEvents() async throws
}

// MARK: - Event Repository

/// Repository pour les événements combinant sources de données locale et distante
class EventRepository: RepositoryProtocol {
    typealias Entity = Event
    typealias ID = String
    
    // MARK: - Properties
    
    private let remoteDataSource: EventRemoteDataSourceProtocol
    private let localDataSource: EventLocalDataSourceProtocol
    
    // MARK: - Initializer
    
    /// Initialise un nouveau repository d'événements
    /// - Parameters:
    ///   - remoteDataSource: Source de données distante pour les événements
    ///   - localDataSource: Source de données locale pour les événements
    init(remoteDataSource: EventRemoteDataSourceProtocol, localDataSource: EventLocalDataSourceProtocol) {
        self.remoteDataSource = remoteDataSource
        self.localDataSource = localDataSource
    }
    
    // MARK: - Repository Protocol Methods
    
    /// Récupère tous les événements, priorité au distant
    func getAll() async throws -> [Event] {
        do {
            // Essayer d'abord la source distante
            let remoteEvents = try await remoteDataSource.fetchEvents()
            
            // Mettre à jour le cache local
            try await localDataSource.saveEvents(remoteEvents)
            
            return remoteEvents
        } catch {
            // Fallback sur la source locale en cas d'erreur réseau
            do {
                let localEvents = try await localDataSource.getEvents()
                return localEvents
            } catch {
                throw RepositoryError.dataSourceError(error)
            }
        }
    }
    
    /// Récupère un événement par son identifiant
    func getById(_ id: String) async throws -> Event? {
        do {
            // Essayer d'abord la source distante
            if let remoteEvent = try await remoteDataSource.fetchEvent(id: id) {
                // Mettre à jour le cache local
                try await localDataSource.saveEvent(remoteEvent)
                return remoteEvent
            }
            return nil
        } catch {
            // Fallback sur la source locale en cas d'erreur réseau
            do {
                return try await localDataSource.getEvent(id: id)
            } catch {
                throw RepositoryError.dataSourceError(error)
            }
        }
    }
    
    /// Crée un nouvel événement
    func create(_ event: Event) async throws -> String {
        do {
            // Créer dans la source distante
            let id = try await remoteDataSource.createEvent(event)
            
            // Mettre à jour localement
            var updatedEvent = event
            updatedEvent.id = id
            try await localDataSource.saveEvent(updatedEvent)
            
            return id
        } catch {
            throw RepositoryError.dataSourceError(error)
        }
    }
    
    /// Met à jour un événement existant
    func update(id: String, with event: Event) async throws {
        do {
            // Mettre à jour dans la source distante
            try await remoteDataSource.updateEvent(id: id, with: event)
            
            // Mettre à jour localement
            var updatedEvent = event
            updatedEvent.id = id
            try await localDataSource.saveEvent(updatedEvent)
        } catch {
            throw RepositoryError.dataSourceError(error)
        }
    }
    
    /// Supprime un événement
    func delete(_ id: String) async throws {
        do {
            // Supprimer dans la source distante
            try await remoteDataSource.deleteEvent(id: id)
            
            // Supprimer localement
            try await localDataSource.deleteEvent(id: id)
        } catch {
            throw RepositoryError.dataSourceError(error)
        }
    }
    
    // MARK: - Specific Methods
    
    /// Récupère les événements triés par date
    /// - Parameter ascending: Ordre de tri (ascendant ou descendant)
    /// - Returns: Événements triés
    func getEventsSortedByDate(ascending: Bool) async throws -> [Event] {
        do {
            // Essayer d'abord la source distante
            let remoteEvents = try await remoteDataSource.fetchEventsSortedByDate(ascending: ascending)
            
            // Mettre à jour le cache local
            try await localDataSource.saveEvents(remoteEvents)
            
            return remoteEvents
        } catch {
            // Fallback sur la source locale en cas d'erreur réseau
            do {
                let localEvents = try await localDataSource.getEvents()
                return localEvents.sorted { ascending ? $0.date < $1.date : $0.date > $1.date }
            } catch {
                throw RepositoryError.dataSourceError(error)
            }
        }
    }
    
    /// Vérifie si la collection d'événements est vide
    /// - Returns: Vrai si la collection est vide
    func isEventsCollectionEmpty() async throws -> Bool {
        do {
            return try await remoteDataSource.isEventsCollectionEmpty()
        } catch {
            // En cas d'erreur sur la source distante, vérifie la source locale
            do {
                let localEvents = try await localDataSource.getEvents()
                return localEvents.isEmpty
            } catch {
                throw RepositoryError.dataSourceError(error)
            }
        }
    }
    
    /// Ajoute des événements d'exemple
    func addSampleEvents() async throws {
        do {
            try await remoteDataSource.addSampleEvents()
            
            // Synchroniser avec le local
            let remoteEvents = try await remoteDataSource.fetchEvents()
            try await localDataSource.saveEvents(remoteEvents)
        } catch {
            throw RepositoryError.dataSourceError(error)
        }
    }
    
    /// Télécharge l'image d'un événement
    /// - Parameter imageData: Données de l'image
    /// - Returns: URL de l'image téléchargée
    func uploadEventImage(imageData: Data) async throws -> String {
        do {
            return try await remoteDataSource.uploadEventImage(imageData: imageData)
        } catch {
            throw RepositoryError.dataSourceError(error)
        }
    }
    
    /// Synchronise les données locales avec les données distantes
    /// - Returns: Nombre d'événements synchronisés
    func syncEvents() async throws -> Int {
        do {
            let remoteEvents = try await remoteDataSource.fetchEvents()
            try await localDataSource.clearEvents()
            try await localDataSource.saveEvents(remoteEvents)
            return remoteEvents.count
        } catch {
            throw RepositoryError.syncError(error)
        }
    }
}
