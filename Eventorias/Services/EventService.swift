//
//  EventService.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 02/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import Combine
import UIKit
import CoreLocation

class EventService {
    private let db = Firestore.firestore()
    private let storage = Storage.storage().reference()
    private let collectionPath = "events"
    
    // Récupérer tous les événements
    func fetchEvents() async throws -> [Event] {
        print("🔥 EventService: Tentative de récupération des événements")
        do {
            let snapshot = try await db.collection(collectionPath)
                .order(by: "date")
                .getDocuments()
                
            print("🔥 EventService: \(snapshot.documents.count) documents récupérés")
            
            let events = snapshot.documents.compactMap { document -> Event? in
                do {
                    return try document.data(as: Event.self)
                } catch {
                    print("🔥 EventService: Erreur lors du décodage d'un événement: \(error.localizedDescription)")
                    return nil
                }
            }
            
            print("🔥 EventService: \(events.count) événements correctement décodés")
            return events
        } catch {
            print("🔥 EventService: ERREUR lors de la récupération des événements: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Rechercher des événements par titre
    func searchEvents(query: String) async throws -> [Event] {
        // La recherche par texte complet n'est pas directement prise en charge par Firestore
        // Une approche simple est d'utiliser la méthode "where" avec l'opérateur ">=" et "<="
        // pour trouver des événements dont le titre commence par la requête
        let queryLowerCase = query.lowercased()
        let endQuery = queryLowerCase.appending("\u{f8ff}")  // Caractère élevé pour couvrir tous les caractères commençant par la requête
        
        let snapshot = try await db.collection(collectionPath)
            .whereField("title", isGreaterThanOrEqualTo: queryLowerCase)
            .whereField("title", isLessThanOrEqualTo: endQuery)
            .getDocuments()
        
        return snapshot.documents.compactMap { try? $0.data(as: Event.self) }
    }
    
    // Filtrer les événements par catégorie
    func filterEventsByCategory(category: String) async throws -> [Event] {
        try await db.collection(collectionPath)
            .whereField("category", isEqualTo: category)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: Event.self) }
    }
    
    // Trier les événements par date (ascendante ou descendante)
    func getEventsSortedByDate(ascending: Bool) async throws -> [Event] {
        try await db.collection(collectionPath)
            .order(by: "date", descending: !ascending)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: Event.self) }
    }
    
    // Ajouter des exemples d'événements pour les tests
    func addSampleEvents() async throws {
        for event in Event.sampleEvents {
            var eventData = try Firestore.Encoder().encode(event)
            // Suppression de l'ID pour que Firestore puisse générer un ID automatiquement
            eventData.removeValue(forKey: "id")
            try await db.collection(collectionPath).addDocument(data: eventData)
        }
    }
    
    // Vérifier si la collection d'événements est vide
    func isEventsCollectionEmpty() async throws -> Bool {
        let snapshot = try await db.collection(collectionPath).limit(to: 1).getDocuments()
        return snapshot.isEmpty
    }
    
    // Créer un nouvel événement
    func createEvent(title: String, description: String, date: Date, location: String, imageURL: String?) async throws -> String {
        var eventData: [String: Any] = [
            "title": title,
            "description": description,
            "date": date,
            "location": location,
            "category": "Autre", // Valeur par défaut, à modifier si nécessaire
            "created_at": Date(),
            "organizer": "" // À remplacer par le nom de l'utilisateur actuel si disponible
        ]
        
        // Obtenir les coordonnées géographiques si possible
        if let coordinates = try? await getCoordinatesForAddress(location) {
            eventData["latitude"] = coordinates.latitude
            eventData["longitude"] = coordinates.longitude
        }
        
        // Si une URL d'image est fournie, l'ajouter aux données
        if let imageURL = imageURL {
            eventData["image_url"] = imageURL
        }
        
        // Ajouter l'événement à Firestore
        let docRef = try await db.collection(collectionPath).addDocument(data: eventData)
        return docRef.documentID
    }
    
    // Télécharger une image sur Firebase Storage
    func uploadImage(imageData: Data) async throws -> String {
        let filename = UUID().uuidString
        let storageRef = storage.child("event_images/\(filename).jpg")
        
        // Compression d'image optimisée
        guard let compressedImageData = compressImageData(imageData, targetSizeKB: 500) else {
            throw NSError(domain: "EventService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Échec de la compression d'image."])
        }
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "uploadDate": ISO8601DateFormatter().string(from: Date()),
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        
        do {
            _ = try await storageRef.putDataAsync(compressedImageData, metadata: metadata)
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
        } catch {
            throw NSError(
                domain: "EventService",
                code: 3,
                userInfo: [NSLocalizedDescriptionKey: "Échec du téléchargement de l'image: \(error.localizedDescription)"]
            )
        }
    }
    
    // Compresse l'image pour atteindre une taille cible
    private func compressImageData(_ data: Data, targetSizeKB: Int) -> Data? {
        // Commence avec une qualité élevée
        var compression: CGFloat = 0.8
        var compressedData = data
        let targetBytes = targetSizeKB * 1024
        
        // Réduit progressivement la qualité jusqu'à atteindre la taille cible ou une limite minimale
        while compressedData.count > targetBytes && compression > 0.1 {
            guard let image = UIImage(data: data) else { return nil }
            guard let newData = image.jpegData(compressionQuality: compression) else { return nil }
            
            compressedData = newData
            compression -= 0.1
        }
        
        return compressedData
    }
    
    // Obtenir les coordonnées géographiques à partir d'une adresse
    func getCoordinatesForAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        let geocoder = CLGeocoder()
        let locations = try await geocoder.geocodeAddressString(address)
        
        guard let location = locations.first?.location?.coordinate else {
            throw NSError(domain: "EventService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Impossible de trouver les coordonnées pour cette adresse."])
        }
        
        return location
    }
}
