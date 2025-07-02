import Foundation
import XCTest
@testable import Eventorias

/// Mock pour APIServiceProtocol facilitant les tests unitaires
final class MockAPIService: APIServiceProtocol {
    // Tracking des appels pour la vérification dans les tests
    var requestCalled = false
    var requestDataCalled = false
    var uploadFileCalled = false
    var buildURLCalled = false
    
    // Variables pour contrôler le comportement des fonctions
    var shouldThrowError = false
    var mockError: APIError = .generic("Erreur simulée")
    
    // Données à retourner par les méthodes mock
    var dataToReturn: Data = Data()
    var responseToReturn: Any?
    
    /// Résultat d'une requête avec type générique
    public func request<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?,
        responseType: T.Type
    ) async throws -> T {
        requestCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        // Si nous avons spécifié une réponse typée à retourner
        if let response = responseToReturn as? T {
            return response
        }
        
        // Sinon, essayons de décoder les données
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: dataToReturn)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// Résultat d'une requête en données brutes
    public func requestData(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?
    ) async throws -> Data {
        requestDataCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return dataToReturn
    }
    
    /// Simulation d'upload de fichier
    public func uploadFile(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: String]?,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fileFieldName: String
    ) async throws -> Data {
        uploadFileCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return dataToReturn
    }
    
    /// Construction d'URL avec paramètres
    public func buildURL(baseURL: URL, queryItems: [URLQueryItem]?) throws -> URL {
        buildURLCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        if let queryItems = queryItems, !queryItems.isEmpty {
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
            components?.queryItems = queryItems
            if let url = components?.url {
                return url
            }
        }
        
        return baseURL
    }
    
    // Méthodes helper pour configurer les retours des tests
    func setResponseForTests<T: Decodable & Encodable>(_ response: T) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            dataToReturn = try encoder.encode(response)
            responseToReturn = response
        } catch {
            print("Erreur lors de l'encodage de la réponse test: \(error)")
        }
    }
}
