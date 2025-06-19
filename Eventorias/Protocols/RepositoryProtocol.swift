//
//  RepositoryProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation

/// Protocole générique pour une source de données
public protocol DataSourceProtocol {
    // Les méthodes spécifiques seront définies dans des protocoles dérivés
}

/// Protocole pour une source de données distante (API, Backend, etc.)
public protocol RemoteDataSourceProtocol: DataSourceProtocol {
    /// L'APIService utilisé pour les appels réseau
    var apiService: APIServiceProtocol { get }
}

/// Protocole pour une source de données locale (Base de données, UserDefaults, etc.)
public protocol LocalDataSourceProtocol: DataSourceProtocol {
    /// Identifiant de la source de données
    var identifier: String { get }
}

/// Type d'erreur pouvant survenir dans un Repository
public enum RepositoryError: Error {
    /// Erreur de la source de données
    case dataSourceError(Error)
    /// Entité non trouvée
    case entityNotFound
    /// Erreur de synchronisation
    case syncError(Error)
    /// Erreur générique
    case generic(String)
}

/// Protocole générique pour un Repository
public protocol RepositoryProtocol {
    /// Type d'entité manipulée par le Repository
    associatedtype Entity
    /// Type d'identifiant pour l'entité
    associatedtype ID
    
    /// Récupère toutes les entités
    /// - Returns: Une collection d'entités
    /// - Throws: RepositoryError
    func getAll() async throws -> [Entity]
    
    /// Récupère une entité par son identifiant
    /// - Parameter id: Identifiant de l'entité
    /// - Returns: L'entité si elle existe, nil sinon
    /// - Throws: RepositoryError
    func getById(_ id: ID) async throws -> Entity?
    
    /// Crée une nouvelle entité
    /// - Parameter entity: Entité à créer
    /// - Returns: L'identifiant de la nouvelle entité
    /// - Throws: RepositoryError
    func create(_ entity: Entity) async throws -> ID
    
    /// Met à jour une entité existante
    /// - Parameters:
    ///   - id: Identifiant de l'entité
    ///   - entity: Nouvelles données de l'entité
    /// - Throws: RepositoryError
    func update(id: ID, with entity: Entity) async throws
    
    /// Supprime une entité
    /// - Parameter id: Identifiant de l'entité à supprimer
    /// - Throws: RepositoryError
    func delete(_ id: ID) async throws
}
