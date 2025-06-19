//
//  APIServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation

/// Types d'erreurs pouvant être renvoyées par les appels API
public enum APIError: Error {
    /// Erreur de requête (URL mal formée, parameters invalides)
    case requestError(String)
    /// Erreur du serveur (status code 4XX, 5XX)
    case serverError(Int, Data?)
    /// Erreur de décodage (JSON invalide ou incompatible)
    case decodingError(Error)
    /// Réponse invalide ou vide
    case invalidResponse
    /// Problème de connectivité réseau
    case networkError(Error)
    /// Erreur d'authentification
    case authenticationError
    /// Erreur générique avec message personnalisé
    case generic(String)
}

/// Protocole définissant le comportement d'un service API
public protocol APIServiceProtocol {
    /// Envoie une requête HTTP et décode le résultat vers le type spécifié
    /// - Parameters:
    ///   - url: URL de la requête
    ///   - method: Méthode HTTP (GET, POST, etc.)
    ///   - headers: En-têtes HTTP optionnels
    ///   - parameters: Paramètres de la requête (pour GET: query params, pour POST: body)
    ///   - responseType: Type de la réponse attendue (doit être Decodable)
    /// - Returns: Objet décodé du type spécifié
    /// - Throws: APIError en cas d'échec
    func request<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?,
        responseType: T.Type
    ) async throws -> T
    
    /// Envoie une requête HTTP et retourne les données brutes
    /// - Parameters:
    ///   - url: URL de la requête
    ///   - method: Méthode HTTP (GET, POST, etc.)
    ///   - headers: En-têtes HTTP optionnels
    ///   - parameters: Paramètres de la requête (pour GET: query params, pour POST: body)
    /// - Returns: Données brutes (Data) de la réponse
    /// - Throws: APIError en cas d'échec
    func requestData(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?
    ) async throws -> Data
    
    /// Envoie une requête multipart pour l'upload de fichiers
    /// - Parameters:
    ///   - url: URL de la requête
    ///   - method: Méthode HTTP (POST or PUT)
    ///   - headers: En-têtes HTTP optionnels
    ///   - parameters: Paramètres de la requête (form fields)
    ///   - fileData: Données du fichier à uploader
    ///   - fileName: Nom du fichier
    ///   - mimeType: Type MIME du fichier
    ///   - fileFieldName: Nom du champ pour le fichier
    /// - Returns: Données brutes de la réponse
    /// - Throws: APIError en cas d'échec
    func uploadFile(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: String]?,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fileFieldName: String
    ) async throws -> Data
    
    /// Construit une URL à partir d'une URL de base et de paramètres de requête
    /// - Parameters:
    ///   - baseURL: URL de base
    ///   - queryItems: Paramètres de requête
    /// - Returns: URL complète
    /// - Throws: APIError.requestError si l'URL est invalide
    func buildURL(baseURL: URL, queryItems: [URLQueryItem]?) throws -> URL
}

/// Méthodes HTTP supportées
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}
