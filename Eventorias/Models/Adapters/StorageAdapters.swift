//
//  StorageAdapters.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseStorage

// Protocol is imported from StorageMetadataProtocol.swift in the same module

// MARK: - Firebase StorageMetadata Adapter

/// Adaptateur pour le type StorageMetadata de Firebase
final class FirebaseStorageMetadataAdapter: StorageMetadataProtocol {
    private let firebaseMetadata: StorageMetadata
    
    init(_ firebaseMetadata: StorageMetadata) {
        self.firebaseMetadata = firebaseMetadata
    }
    
    init() {
        self.firebaseMetadata = StorageMetadata()
    }
    
    var contentType: String? {
        get { return firebaseMetadata.contentType }
        set { firebaseMetadata.contentType = newValue }
    }
    
    var size: Int64 {
        return firebaseMetadata.size
    }
    
    var timeCreated: Date? {
        return firebaseMetadata.timeCreated
    }
    
    var updated: Date? {
        return firebaseMetadata.updated
    }
    
    var name: String? {
        return firebaseMetadata.name
    }
    
    var path: String? {
        return firebaseMetadata.path
    }
    
    var customMetadata: [String: String]? {
        get { return firebaseMetadata.customMetadata }
        set { firebaseMetadata.customMetadata = newValue }
    }
    
    /// Convertit l'adaptateur en StorageMetadata de Firebase
    func toFirebaseStorageMetadata() -> StorageMetadata {
        return firebaseMetadata
    }
}
