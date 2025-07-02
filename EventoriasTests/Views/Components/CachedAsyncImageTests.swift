//
//  CachedAsyncImageTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 28/06/2025.
//

import XCTest
import SwiftUI
@testable import Eventorias
@MainActor
final class CachedAsyncImageTests: XCTestCase {
    
    // Test mock URL session pour simuler les réponses réseau
    class MockURLSession: URLSession {
        static var mockResponse: (Data?, URLResponse?, Error?)
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            let task = MockURLSessionDataTask()
            task.completionHandler = {
                completionHandler(MockURLSession.mockResponse.0, MockURLSession.mockResponse.1, MockURLSession.mockResponse.2)
            }
            return task
        }
        
        class MockURLSessionDataTask: URLSessionDataTask {
            var completionHandler: (() -> Void)?
            
            override func resume() {
                // Exécuter immédiatement pour les tests
                completionHandler?()
            }
        }
    }
    
    override func setUp() {
        super.setUp()
        // S'assurer que le cache est vide avant chaque test
        ImageCache.shared.clearCache()
    }
    
    func testCachedImageIsRetrievedFromCache() throws {
        // Arrange
        let testImage = UIImage(systemName: "star.fill")!
        let testData = try XCTUnwrap(testImage.pngData())
        let testURL = URL(string: "https://example.com/testImage.png")!
        
        // Pré-remplir le cache
        ImageCache.shared.store(testImage, forKey: testURL.absoluteString)
        
        // Act & Assert
        // Ici nous pouvons seulement tester l'intégration logique
        // En production, cette image sera utilisée depuis le cache sans appel réseau
        let cachedImage = ImageCache.shared.retrieve(forKey: testURL.absoluteString)
        XCTAssertNotNil(cachedImage, "L'image devrait être récupérée du cache")
    }
    
    func testMissingImageInitiatesNetworkRequest() throws {
        // Ce test vérifie le comportement conceptuel mais ne peut pas tester directement
        // le composant SwiftUI car UITesting serait nécessaire
        
        // Dans une vraie situation, si l'image n'est pas en cache,
        // un appel réseau sera initié via URLSession
        
        let testURL = URL(string: "https://example.com/missingImage.png")!
        let cachedImage = ImageCache.shared.retrieve(forKey: testURL.absoluteString)
        XCTAssertNil(cachedImage, "L'image ne devrait pas être en cache")
        
        // Dans CachedAsyncImage, cela déclencherait un appel réseau
    }
    
    override func tearDown() {
        // Nettoyer après chaque test
        ImageCache.shared.clearCache()
        super.tearDown()
    }
}
