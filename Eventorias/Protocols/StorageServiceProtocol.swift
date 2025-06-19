//
//  StorageServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 17/06/2025.
//

import Foundation
import FirebaseStorage
import UIKit

/// Protocole définissant les opérations de stockage de fichiers
protocol StorageServiceProtocol {
    /// Télécharge une image vers le stockage
    /// - Parameters:
    ///   - imageData: Données de l'image
    ///   - path: Chemin de destination dans le stockage
    ///   - metadata: Métadonnées optionnelles pour l'image
    /// - Returns: URL de téléchargement de l'image sous forme de chaîne
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadataProtocol?) async throws -> String
    
    /// Récupère l'URL de téléchargement d'un fichier
    /// - Parameter path: Chemin du fichier dans le stockage
    /// - Returns: URL du fichier
    func getDownloadURL(for path: String) async throws -> URL
}

// Implémentation réelle avec Firebase
class FirebaseStorageService: StorageServiceProtocol {
    private let storage = Storage.storage()
    
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadataProtocol?) async throws -> String {
        let storageRef = storage.reference().child(path)
        
        // Convertir le metadata abstrait en metadata Firebase si présent
        let firebaseMetadata: StorageMetadata?
        if let metadata = metadata {
            if let adapter = metadata as? FirebaseStorageMetadataAdapter {
                firebaseMetadata = adapter.toFirebaseStorageMetadata()
            } else {
                // Créer un nouveau metadata Firebase avec les informations du protocol
                let newMetadata = StorageMetadata()
                newMetadata.contentType = metadata.contentType
                newMetadata.customMetadata = metadata.customMetadata
                firebaseMetadata = newMetadata
            }
        } else {
            firebaseMetadata = nil
        }
        
        _ = try await storageRef.putDataAsync(imageData, metadata: firebaseMetadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL.absoluteString
    }
    
    func getDownloadURL(for path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        return try await storageRef.downloadURL()
    }
}

// Mock pour les tests
class MockStorageService: StorageServiceProtocol {
    var shouldSucceed: Bool = true
    var mockDownloadURL: String = "https://mock.firebase.com/test-image.jpg"
    var uploadProgress: Double = 1.0
    var mockError: Error?
    
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadataProtocol?) async throws -> String {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockStorage", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        }
        
        // Simuler un délai d'upload
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
        
        return mockDownloadURL
    }
    
    func getDownloadURL(for path: String) async throws -> URL {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockStorage", code: 404, userInfo: [NSLocalizedDescriptionKey: "URL not found"])
        }
        
        guard let url = URL(string: mockDownloadURL) else {
            throw NSError(domain: "MockStorage", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        return url
    }
}
