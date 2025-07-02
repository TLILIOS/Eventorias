//
//  StorageMetadataProtocol.swift
//  Eventorias
//
//  Created on 20/06/2025.
//

import Foundation
import FirebaseStorage

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
