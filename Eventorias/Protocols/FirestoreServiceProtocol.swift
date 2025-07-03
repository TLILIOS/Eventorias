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
    
    // MARK: - Invitation Management
    
    /// Create a new invitation in Firestore
    /// - Parameter invitation: The invitation to create
    func createInvitation(_ invitation: Invitation) async throws
    
    /// Update an existing invitation in Firestore
    /// - Parameter invitation: The invitation with updated data
    func updateInvitation(_ invitation: Invitation) async throws
    
    /// Delete an invitation from Firestore
    /// - Parameter invitationId: The ID of the invitation to delete
    func deleteInvitation(_ invitationId: String) async throws
    
    /// Get all invitations for a specific event
    /// - Parameter eventId: The ID of the event
    /// - Returns: Array of invitations
    func getEventInvitations(eventId: String) async throws -> [Invitation]
    
    /// Get all invitations where the current user is the invitee
    /// - Parameter userId: The ID of the user
    /// - Returns: Array of invitations
    func getUserInvitations(userId: String) async throws -> [Invitation]
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
    
    // MARK: - Invitation Management
    
    func createInvitation(_ invitation: Invitation) async throws {
        let invitationRef = db.collection("invitations").document(invitation.id ?? UUID().uuidString)
        try await invitationRef.setData(from: invitation)
    }
    
    func updateInvitation(_ invitation: Invitation) async throws {
        guard let id = invitation.id else {
            throw NSError(
                domain: "FirebaseFirestoreService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invitation ID is required"]
            )
        }
        
        let invitationRef = db.collection("invitations").document(id)
        try await invitationRef.setData(from: invitation, merge: true)
    }
    
    func deleteInvitation(_ invitationId: String) async throws {
        let invitationRef = db.collection("invitations").document(invitationId)
        try await invitationRef.delete()
    }
    
    func getEventInvitations(eventId: String) async throws -> [Invitation] {
        let query = db.collection("invitations")
            .whereField("eventId", isEqualTo: eventId)
        
        let querySnapshot = try await query.getDocuments()
        var invitations: [Invitation] = []
        
        for document in querySnapshot.documents {
            if let invitation = try? document.data(as: Invitation.self) {
                invitations.append(invitation)
            }
        }
        
        return invitations
    }
    
    func getUserInvitations(userId: String) async throws -> [Invitation] {
        let query = db.collection("invitations")
            .whereField("inviteeId", isEqualTo: userId)
        
        let querySnapshot = try await query.getDocuments()
        var invitations: [Invitation] = []
        
        for document in querySnapshot.documents {
            if let invitation = try? document.data(as: Invitation.self) {
                invitations.append(invitation)
            }
        }
        
        return invitations
    }
}

// Implementation simplifiée pour les exemples et tests rapides
class ExampleFirestoreService: FirestoreServiceProtocol {
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
    
    func createInvitation(_ invitation: Invitation) async throws {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        // Simuler création d'invitation
    }
    
    func updateInvitation(_ invitation: Invitation) async throws {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        // Simuler mise à jour d'invitation
    }
    
    func deleteInvitation(_ invitationId: String) async throws {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        // Simuler suppression d'invitation
    }
    
    func getEventInvitations(eventId: String) async throws -> [Invitation] {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        // Simuler récupération des invitations pour un événement
        return []
    }
    
    func getUserInvitations(userId: String) async throws -> [Invitation] {
        if !shouldSucceed {
            if let error = mockError {
                throw error
            }
            throw NSError(domain: "MockFirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock error"])
        }
        // Simuler récupération des invitations pour un utilisateur
        return []
    }
}
