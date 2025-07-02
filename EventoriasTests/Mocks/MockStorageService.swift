//
//  MockStorageService.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 27/06/2025.
//

import Foundation
import FirebaseStorage
@testable import Eventorias

/// Mock de métadonnées pour le stockage
class MockStorageMetadata: StorageMetadataProtocol {
    var contentType: String?
    var customMetadata: [String: String]?
    
    // Propriétés requises par StorageMetadataProtocol
    var size: Int64 = 0
    var timeCreated: Date? = Date()
    var updated: Date? = Date()
    var name: String? = "mock-file.jpg"
    var path: String? = "mock/path/file.jpg"
    
    init(contentType: String? = nil, customMetadata: [String: String]? = nil, size: Int64 = 0, name: String? = "mock-file.jpg", path: String? = "mock/path/file.jpg") {
        self.contentType = contentType
        self.customMetadata = customMetadata
        self.size = size
        self.name = name
        self.path = path
        self.timeCreated = Date()
        self.updated = Date()
    }
}

/// Mock pour StorageServiceProtocol permettant de simuler les opérations de stockage
/// sans interagir avec Firebase
class MockStorageService: StorageServiceProtocol {
    // Variables pour suivre les appels aux méthodes
    var uploadImageCalled = false
    var getDownloadURLCalled = false
    
    // Variables pour contrôler le comportement simulé
    var shouldThrowError = false
    var mockError: Error = NSError(domain: "MockStorage", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée de stockage"])
    var mockDownloadURL: URL = URL(string: "https://example.com/mock-image.jpg")!
    var mockDownloadURLString = "https://example.com/mock-image.jpg" // Pour compatibilité avec les tests existants
    var uploadDelay: TimeInterval = 0.1 // Secondes
    
    /// Télécharge une image vers le stockage simulé
    /// - Parameters:
    ///   - imageData: Données de l'image
    ///   - path: Chemin de destination dans le stockage
    ///   - metadata: Métadonnées optionnelles pour l'image
    /// - Returns: URL de téléchargement de l'image sous forme de chaîne
    /// - Throws: Erreur simulée si shouldThrowError est true
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadataProtocol?) async throws -> String {
        uploadImageCalled = true
        
        // Simuler un délai d'upload
        try await Task.sleep(nanoseconds: UInt64(uploadDelay * 1_000_000_000))
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockDownloadURLString
    }
    
    /// Récupère l'URL de téléchargement d'un fichier simulé
    /// - Parameter path: Chemin du fichier dans le stockage
    /// - Returns: URL du fichier
    /// - Throws: Erreur simulée si shouldThrowError est true
    func getDownloadURL(for path: String) async throws -> URL {
        getDownloadURLCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        return mockDownloadURL
    }
    
    /// Réinitialise les variables de suivi pour les tests
    func reset() {
        uploadImageCalled = false
        getDownloadURLCalled = false
        shouldThrowError = false
    }
}
