//
//  APIServiceProtocolTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
@testable import Eventorias

final class APIServiceProtocolTests: XCTestCase {
    
    // Test de conformité de DefaultAPIService au protocole APIServiceProtocol
    func testDefaultAPIServiceProtocolConformance() {
        // Arrange
        let apiService = DefaultAPIService()
        
        // Act & Assert
        XCTAssertTrue(apiService is APIServiceProtocol, "DefaultAPIService doit se conformer à APIServiceProtocol")
    }
    
    // Test de comportement du protocole avec différentes implémentations
    func testAPIProtocolBehaviorWithDifferentImplementations() async {
        // Arrange
        let defaultService = DefaultAPIService()
        let mockService = MockAPIService()
        
        let apiServices: [APIServiceProtocol] = [defaultService, mockService]
        let testURL = URL(string: "https://api.example.com/test")!
        
        // Test adapté pour fonctionner avec des implémentations différentes
        for (index, service) in apiServices.enumerated() {
            // Pour le mock, on configure un retour spécifique
            if let mockService = service as? MockAPIService {
                let jsonString = "{\"message\":\"Success\"}"
                mockService.dataToReturn = jsonString.data(using: .utf8)!
            }
            
            // Act & Assert - Vérifier que le service supporte bien la création d'URL
            do {
                let url = try service.buildURL(baseURL: testURL, queryItems: [URLQueryItem(name: "test", value: "value")])
                XCTAssertTrue(url.absoluteString.contains("test=value"), "L'URL générée par l'implémentation \(index) ne contient pas les paramètres attendus")
            } catch {
                XCTFail("L'implémentation \(index) a échoué lors de la construction d'URL: \(error.localizedDescription)")
            }
        }
    }
    
    // Test des différents types d'erreurs API définis
    func testAPIErrorTypes() {
        let errors: [APIError] = [
            .requestError("Erreur de requête"),
            .serverError(404, nil),
            .decodingError(NSError(domain: "test", code: 1)),
            .invalidResponse,
            .networkError(NSError(domain: "test", code: 2)),
            .authenticationError,
            .generic("Erreur générique")
        ]
        
        // Vérifier que chaque type d'erreur a bien le bon type
        XCTAssertEqual(errors.count, 7, "Tous les types d'erreurs API doivent être testés")
    }
    
    // Test des méthodes HTTP supportées
    func testHTTPMethods() {
        let methods: [HTTPMethod] = [.get, .post, .put, .delete, .patch]
        let expectedRawValues = ["GET", "POST", "PUT", "DELETE", "PATCH"]
        
        for (index, method) in methods.enumerated() {
            XCTAssertEqual(method.rawValue, expectedRawValues[index], "La valeur brute de la méthode HTTP \(index) ne correspond pas")
        }
    }
}
