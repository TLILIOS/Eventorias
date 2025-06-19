//
//  DefaultAPIService.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation

/// Implémentation par défaut du service API utilisant URLSession
class DefaultAPIService: APIServiceProtocol {
    
    // MARK: - Properties
    
    /// Session URL pour les requêtes réseau
    private let session: URLSession
    
    /// Délai d'expiration pour les requêtes
    private let timeoutInterval: TimeInterval
    
    // MARK: - Initialization
    
    /// Initialise un nouveau service API
    /// - Parameters:
    ///   - session: Session URL à utiliser (par défaut .shared)
    ///   - timeoutInterval: Délai d'expiration en secondes (par défaut 30 secondes)
    init(session: URLSession = .shared, timeoutInterval: TimeInterval = 30.0) {
        self.session = session
        self.timeoutInterval = timeoutInterval
    }
    
    // MARK: - Public Methods
    
    /// Voir APIServiceProtocol.request
    public func request<T: Decodable>(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?,
        responseType: T.Type
    ) async throws -> T {
        let data = try await requestData(
            url: url,
            method: method,
            headers: headers,
            parameters: parameters
        )
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            decoder.keyDecodingStrategy = .useDefaultKeys
            
            return try decoder.decode(responseType, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }
    
    /// Voir APIServiceProtocol.requestData
    public func requestData(
        url: URL,
        method: HTTPMethod,
        headers: [String: String]?,
        parameters: [String: Any]?
    ) async throws -> Data {
        // Créer la requête
        var request = createRequest(url: url, method: method, headers: headers)
        
        // Ajouter les paramètres
        if let parameters = parameters {
            try addParameters(to: &request, method: method, parameters: parameters)
        }
        
        do {
            // Exécuter la requête
            let (data, response) = try await session.data(for: request)
            
            // Vérifier la réponse
            try validateResponse(response, data: data)
            
            return data
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.generic(error.localizedDescription)
        }
    }
    
    /// Voir APIServiceProtocol.uploadFile
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
        // Vérifier que la méthode est POST ou PUT
        guard method == .post || method == .put else {
            throw APIError.requestError("La méthode \(method.rawValue) n'est pas supportée pour l'upload de fichiers")
        }
        
        // Créer la requête
        var request = createRequest(url: url, method: method, headers: headers)
        
        // Générer un boundary pour la requête multipart
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Créer le corps de la requête multipart
        let body = createMultipartBody(
            boundary: boundary,
            parameters: parameters,
            fileData: fileData,
            fileName: fileName,
            mimeType: mimeType,
            fileFieldName: fileFieldName
        )
        
        request.httpBody = body
        
        do {
            // Exécuter la requête
            let (data, response) = try await session.data(for: request)
            
            // Vérifier la réponse
            try validateResponse(response, data: data)
            
            return data
        } catch let urlError as URLError {
            throw APIError.networkError(urlError)
        } catch let apiError as APIError {
            throw apiError
        } catch {
            throw APIError.generic(error.localizedDescription)
        }
    }
    
    /// Voir APIServiceProtocol.buildURL
    public func buildURL(baseURL: URL, queryItems: [URLQueryItem]?) throws -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            throw APIError.requestError("URL invalide: \(baseURL.absoluteString)")
        }
        
        if let items = queryItems {
            components.queryItems = items
        }
        
        guard let url = components.url else {
            throw APIError.requestError("Impossible de construire l'URL avec les paramètres fournis")
        }
        
        return url
    }
    
    // MARK: - Private Methods
    
    /// Crée une requête URLRequest avec les paramètres spécifiés
    /// - Parameters:
    ///   - url: URL de la requête
    ///   - method: Méthode HTTP
    ///   - headers: En-têtes HTTP optionnels
    /// - Returns: URLRequest configurée
    private func createRequest(url: URL, method: HTTPMethod, headers: [String: String]?) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = method.rawValue
        
        // Ajouter les en-têtes par défaut
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Ajouter les en-têtes supplémentaires
        if let headers = headers {
            for (key, value) in headers {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }
        
        return request
    }
    
    /// Ajoute les paramètres à la requête selon la méthode HTTP
    /// - Parameters:
    ///   - request: Requête à modifier
    ///   - method: Méthode HTTP
    ///   - parameters: Paramètres à ajouter
    private func addParameters(to request: inout URLRequest, method: HTTPMethod, parameters: [String: Any]) throws {
        switch method {
        case .get:
            // Pour GET, ajouter les paramètres à l'URL
            guard let url = request.url else {
                throw APIError.requestError("URL invalide")
            }
            
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
                throw APIError.requestError("Impossible de parser l'URL")
            }
            
            var queryItems = components.queryItems ?? []
            for (key, value) in parameters {
                if let stringValue = String(describing: value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                    queryItems.append(URLQueryItem(name: key, value: stringValue))
                }
            }
            
            components.queryItems = queryItems
            request.url = components.url
            
        case .post, .put, .patch, .delete:
            // Pour POST, PUT, PATCH et DELETE, ajouter les paramètres au corps
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
                request.httpBody = jsonData
            } catch {
                throw APIError.requestError("Erreur lors de la sérialisation JSON: \(error.localizedDescription)")
            }
        }
    }
    
    /// Crée le corps d'une requête multipart
    /// - Parameters:
    ///   - boundary: Délimiteur pour séparer les parties du corps
    ///   - parameters: Paramètres textuels à inclure
    ///   - fileData: Données du fichier
    ///   - fileName: Nom du fichier
    ///   - mimeType: Type MIME du fichier
    ///   - fileFieldName: Nom du champ pour le fichier
    /// - Returns: Données du corps multipart
    private func createMultipartBody(
        boundary: String,
        parameters: [String: String]?,
        fileData: Data,
        fileName: String,
        mimeType: String,
        fileFieldName: String
    ) -> Data {
        var body = Data()
        let boundaryPrefix = "--\(boundary)\r\n"
        
        // Ajouter les paramètres textuels
        if let parameters = parameters {
            for (key, value) in parameters {
                body.append(boundaryPrefix.data(using: .utf8)!)
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
                body.append("\(value)\r\n".data(using: .utf8)!)
            }
        }
        
        // Ajouter le fichier
        body.append(boundaryPrefix.data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileName)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(fileData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return body
    }
    
    /// Valide la réponse HTTP
    /// - Parameters:
    ///   - response: Réponse HTTP
    ///   - data: Données reçues
    /// - Throws: APIError en cas d'erreur
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Succès
            break
        case 401:
            throw APIError.authenticationError
        case 400...499:
            throw APIError.serverError(httpResponse.statusCode, data)
        case 500...599:
            throw APIError.serverError(httpResponse.statusCode, data)
        default:
            throw APIError.serverError(httpResponse.statusCode, data)
        }
    }
}
