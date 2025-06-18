//
//  StorageServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 17/06/2025.
//

import Foundation
import FirebaseStorage
import UIKit

protocol StorageServiceProtocol {
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadata?) async throws -> String
    func getDownloadURL(for path: String) async throws -> URL
}

// Implémentation réelle
class FirebaseStorageService: StorageServiceProtocol {
    private let storage = Storage.storage()
    
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadata?) async throws -> String {
        let storageRef = storage.reference().child(path)
        _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
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
    
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadata?) async throws -> String {
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
