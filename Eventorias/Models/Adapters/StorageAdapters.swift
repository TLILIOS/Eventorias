//
//  StorageAdapters.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseStorage

// MARK: - StorageMetadata Protocol

/// Protocole définissant les métadonnées de stockage
public protocol StorageMetadataProtocol {
    /// Le type de contenu du fichier (par exemple, "image/jpeg")
    var contentType: String? { get set }
    
    /// La taille du fichier en octets
    var size: Int64 { get }
    
    /// La date de création du fichier
    var timeCreated: Date? { get }
    
    /// La date de la dernière modification du fichier
    var updated: Date? { get }
    
    /// Le nom du fichier
    var name: String? { get }
    
    /// Le chemin complet du fichier
    var path: String? { get }
    
    /// Les métadonnées personnalisées
    var customMetadata: [String: String]? { get set }
}

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
