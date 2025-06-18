//
//  FirestoreServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 17/06/2025.
//

import Foundation
import FirebaseFirestore

protocol FirestoreServiceProtocol {
    func createEvent(_ event: Event) async throws
    func updateEvent(_ event: Event) async throws
}
// Implémentation réelle
class FirebaseFirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()
    
    func createEvent(_ event: Event) async throws {
        // ✅ Unwrapping sécurisé avec valeur par défaut
        let eventRef = db.collection("events").document(event.id ?? UUID().uuidString)
        try await eventRef.setData(from: event)
    }
    
    func updateEvent(_ event: Event) async throws {
        // ✅ Unwrapping sécurisé avec valeur par défaut
        let eventRef = db.collection("events").document(event.id ?? UUID().uuidString)
        try await eventRef.setData(from: event)
    }
}


// Mock pour les tests
class MockFirestoreService: FirestoreServiceProtocol {
    var shouldSucceed: Bool = true
    var mockError: Error?
    var createdEvents: [Event] = []
    
    func createEvent(_ event: Event) async throws {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockFirestore", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firestore error"])
        }
        
        createdEvents.append(event)
    }
    
    func updateEvent(_ event: Event) async throws {
        if !shouldSucceed {
            throw mockError ?? NSError(domain: "MockFirestore", code: 500, userInfo: [NSLocalizedDescriptionKey: "Firestore error"])
        }
        
        // Mise à jour dans le mock
        if let index = createdEvents.firstIndex(where: { $0.id == event.id }) {
            createdEvents[index] = event
        }
    }
}
