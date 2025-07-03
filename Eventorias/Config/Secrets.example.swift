//
//  Secrets.example.swift
//  Eventorias
//
//  Created on 03/07/2025.
//

import Foundation

/// Structure d'exemple pour les clés API et informations sensibles
/// Pour utiliser ce fichier :
/// 1. Copiez ce fichier et renommez-le en "Secrets.swift"
/// 2. Remplacez les valeurs d'exemple par vos propres clés API
/// 3. Assurez-vous que Secrets.swift est dans .gitignore
/// 4. Remplacez le nom de la structure par 'Secrets' dans votre copie
struct SecretsExample {
    // MARK: - API Keys
    
    /// Clé API pour les services de cartographie
    static let mapAPIKey = "REPLACE_WITH_YOUR_MAP_API_KEY"
    
    /// Clé API pour les services de météo
    static let weatherAPIKey = "REPLACE_WITH_YOUR_WEATHER_API_KEY"
    
    /// Clé API pour les services d'analyse
    static let analyticsAPIKey = "REPLACE_WITH_YOUR_ANALYTICS_API_KEY"
    
    // MARK: - Endpoints
    
    /// URL de base pour l'API backend
    static let apiBaseURL = "https://api.example.com"
    
    // MARK: - Authentication
    
    /// Client ID pour l'authentification OAuth
    static let oauthClientID = "REPLACE_WITH_YOUR_OAUTH_CLIENT_ID"
    
    /// Client Secret pour l'authentification OAuth
    static let oauthClientSecret = "REPLACE_WITH_YOUR_OAUTH_CLIENT_SECRET"
}
