//
//  URLSessionTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import XCTest
@testable import Eventorias

final class URLSessionTests: XCTestCase {

    // Test de la classe URLSession avec async/await
    func testURLSessionAsyncAwait() async {
        // Nous utilisons une implémentation personnalisée de URLSession pour les tests
        let mockURLSession = MockURLSession()
        
        // Configuration du mock pour simuler une réponse réussie
        let testURL = URL(string: "https://api.example.com/data")!
        let jsonString = """
        {
            "id": "test123",
            "name": "Test Item",
            "active": true
        }
        """
        
        // Préparation des données de test et de la réponse HTTP
        let testData = jsonString.data(using: .utf8)!
        let response = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: nil)!
        
        // Configuration du mock pour renvoyer nos données de test
        mockURLSession.mockData = testData
        mockURLSession.mockResponse = response
        mockURLSession.mockError = nil
        
        do {
            // Création et exécution de la requête avec async/await
            let request = URLRequest(url: testURL)
            let (data, urlResponse) = try await mockURLSession.data(for: request)
            
            // Assertions
            XCTAssertEqual(data, testData, "Les données reçues ne correspondent pas aux données attendues")
            XCTAssertEqual((urlResponse as? HTTPURLResponse)?.statusCode, 200, "Le code de statut devrait être 200")
            XCTAssertTrue(mockURLSession.dataForRequestCalled, "La méthode data(for:) n'a pas été appelée")
            
            // Décodage JSON pour tester l'intégration complète
            struct TestItem: Codable {
                let id: String
                let name: String
                let active: Bool
            }
            
            let decoder = JSONDecoder()
            let testItem = try decoder.decode(TestItem.self, from: data)
            
            XCTAssertEqual(testItem.id, "test123", "L'ID décodé ne correspond pas")
            XCTAssertEqual(testItem.name, "Test Item", "Le nom décodé ne correspond pas")
            XCTAssertTrue(testItem.active, "Le statut actif décodé ne correspond pas")
            
        } catch {
            XCTFail("La requête async/await a échoué: \(error.localizedDescription)")
        }
    }
    
    // Test de gestion des erreurs avec async/await
    func testURLSessionAsyncAwaitError() async {
        // Configuration du mock pour simuler une erreur
        let mockURLSession = MockURLSession()
        let testURL = URL(string: "https://api.example.com/error")!
        let testError = NSError(domain: "URLSessionTestError", code: 999, userInfo: [NSLocalizedDescriptionKey: "Erreur de réseau simulée"])
        
        mockURLSession.mockData = nil
        mockURLSession.mockResponse = nil
        mockURLSession.mockError = testError
        
        do {
            let request = URLRequest(url: testURL)
            _ = try await mockURLSession.data(for: request)
            XCTFail("La requête aurait dû échouer")
        } catch let error as NSError {
            // Vérification que l'erreur est correctement propagée
            XCTAssertEqual(error.domain, "URLSessionTestError", "Le domaine d'erreur ne correspond pas")
            XCTAssertEqual(error.code, 999, "Le code d'erreur ne correspond pas")
            XCTAssertTrue(mockURLSession.dataForRequestCalled, "La méthode data(for:) n'a pas été appelée")
        } catch {
            XCTFail("Type d'erreur inattendu: \(error)")
        }
    }
    
    // Test de timeout avec async/await
    func testURLSessionAsyncAwaitTimeout() async {
        let mockURLSession = MockURLSession()
        let testURL = URL(string: "https://api.example.com/timeout")!
        
        // Configuration du mock pour simuler un timeout
        mockURLSession.simulateTimeout = true
        mockURLSession.timeoutDelay = 0.1 // 100ms pour accélérer le test
        
        do {
            let request = URLRequest(url: testURL)
            _ = try await mockURLSession.data(for: request)
            XCTFail("La requête aurait dû échouer avec un timeout")
        } catch {
            // Vérification que l'erreur de timeout a bien été générée
            XCTAssertTrue(mockURLSession.dataForRequestCalled, "La méthode data(for:) n'a pas été appelée")
        }
    }
}

// MARK: - Mock URLSession pour les tests

class MockURLSession {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var simulateTimeout: Bool = false
    var timeoutDelay: TimeInterval = 0.1
    
    var dataForRequestCalled = false
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        dataForRequestCalled = true
        
        if simulateTimeout {
            // Simuler un délai puis échouer avec un timeout
            try await Task.sleep(nanoseconds: UInt64(timeoutDelay * 1_000_000_000))
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorTimedOut, userInfo: nil)
        }
        
        if let error = mockError {
            throw error
        }
        
        guard let data = mockData, let response = mockResponse else {
            throw NSError(domain: "MockURLSessionError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Données ou réponse mock non configurées"])
        }
        
        return (data, response)
    }
}
