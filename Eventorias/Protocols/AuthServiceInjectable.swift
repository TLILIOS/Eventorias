//
//  AuthServiceInjectable.swift
//  Eventorias
//
//  Created on 02/07/2025.
//

import Foundation

/// Protocole pour permettre l'injection de dépendances dans les services d'authentification
@MainActor
protocol AuthServiceInjectable {
    /// Injecte un fournisseur d'authentification alternatif
    /// Utile pour les tests unitaires
    func injectAuthProvider(_ provider: AuthProviderProtocol)
}
