//
//  FirestoreServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 17/06/2025.
//

import Foundation
import FirebaseFirestore

protocol FirestoreServiceProtocol {
    /// Create a new event in Firestore
    func createEvent(_ event: Event) async throws
    
    /// Update an existing event in Firestore
    func updateEvent(_ event: Event) async throws
    
    /// Get an event document by its ID
    /// - Parameter eventID: ID of the event to fetch
    /// - Returns: Document snapshot containing event data
    /// - Throws: Error if retrieval fails
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol
    
    /// Get a sample event by ID when it's not found in Firestore
    /// - Parameter eventID: ID of the event to fetch from samples
    /// - Returns: Sample event if found
    /// - Throws: Error if no matching sample event exists
    func getSampleEvent(eventID: String) throws -> Event
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
    
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol {
        let snapshot = try await db.collection("events").document(eventID).getDocument()
        // Use a FirebaseDocumentSnapshotWrapper to adapt Firebase's DocumentSnapshot to our protocol
        return FirebaseDocumentSnapshotWrapper(snapshot: snapshot)
    }
    
    func getSampleEvent(eventID: String) throws -> Event {
        guard let sampleEvent = Event.sampleEvents.first(where: { $0.id == eventID }) else {
            throw EventDetailsError.noData
        }
        return sampleEvent
    }
}

// Mock pour les tests
class MockFirestoreService: FirestoreServiceProtocol {
    var shouldSucceed: Bool = true
    var mockError: Error?
    var createdEvents: [Event] = []
    var mockEvent: Event = Event.sampleEvents.first!
    var mockDocumentSnapshot: DocumentSnapshotProtocol?
    
    func createEvent(_ event: Event) async throws {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        createdEvents.append(event)
    }
    
    func updateEvent(_ event: Event) async throws {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        // Simuler mise à jour
    }
    
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        if let snapshot = mockDocumentSnapshot {
            return snapshot
        }
        
        // Fournir un document snapshot par défaut pour les tests
        throw NSError(domain: "MockFirestoreService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Document not found"])
    }
    
    func getSampleEvent(eventID: String) throws -> Event {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        
        return mockEvent
    }
}
