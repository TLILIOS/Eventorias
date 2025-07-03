//
//  Invitation.swift
//  Eventorias
//
//  Created on 03/07/2025
//

import Foundation
import FirebaseFirestore

enum InvitationStatus: String, Codable, CaseIterable, Identifiable {
    case pending = "En attente"
    case accepted = "Acceptée"
    case declined = "Refusée"
    
    var id: String { self.rawValue }
    
    // Icône associée à chaque statut
    var icon: String {
        switch self {
        case .pending:
            return "clock"
        case .accepted:
            return "checkmark.circle"
        case .declined:
            return "xmark.circle"
        }
    }
    
    // Couleur associée à chaque statut (sous forme de nom)
    var colorName: String {
        switch self {
        case .pending:
            return "orange"
        case .accepted:
            return "green"
        case .declined:
            return "red"
        }
    }
}

struct Invitation: Identifiable, Codable {
    @DocumentID var id: String?
    var eventId: String
    var inviterId: String
    var inviteeId: String
    var inviteeName: String
    var inviteeEmail: String?
    var inviteePhotoURL: String?
    var status: InvitationStatus
    var message: String?
    var sentAt: Date
    var respondedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case eventId = "event_id"
        case inviterId = "inviter_id"
        case inviteeId = "invitee_id"
        case inviteeName = "invitee_name"
        case inviteeEmail = "invitee_email"
        case inviteePhotoURL = "invitee_photo_url"
        case status
        case message
        case sentAt = "sent_at"
        case respondedAt = "responded_at"
    }
    
    // Crée une nouvelle invitation avec le statut "en attente" par défaut
    static func create(eventId: String, inviterId: String, inviteeId: String, inviteeName: String, 
                      inviteeEmail: String? = nil, inviteePhotoURL: String? = nil, message: String? = nil) -> Invitation {
        return Invitation(
            id: nil,
            eventId: eventId,
            inviterId: inviterId,
            inviteeId: inviteeId,
            inviteeName: inviteeName,
            inviteeEmail: inviteeEmail,
            inviteePhotoURL: inviteePhotoURL,
            status: .pending,
            message: message,
            sentAt: Date(),
            respondedAt: nil
        )
    }
    
    // Méthodes pour mettre à jour le statut
    func accepted() -> Invitation {
        var updated = self
        updated.status = .accepted
        updated.respondedAt = Date()
        return updated
    }
    
    func declined() -> Invitation {
        var updated = self
        updated.status = .declined
        updated.respondedAt = Date()
        return updated
    }
}

// Extension pour des données de test
extension Invitation {
    static var samples: [Invitation] {
        [
            Invitation(
                id: UUID().uuidString,
                eventId: "1",
                inviterId: "user1",
                inviteeId: "user2",
                inviteeName: "Marie Dupont",
                inviteeEmail: "marie@example.com",
                inviteePhotoURL: nil,
                status: .pending,
                message: "J'espère que tu pourras venir !",
                sentAt: Date().addingTimeInterval(-60*60*24*2),
                respondedAt: nil
            ),
            Invitation(
                id: UUID().uuidString,
                eventId: "1",
                inviterId: "user1",
                inviteeId: "user3",
                inviteeName: "Jean Martin",
                inviteeEmail: "jean@example.com",
                inviteePhotoURL: nil,
                status: .accepted,
                message: "Ce sera sympa de te voir !",
                sentAt: Date().addingTimeInterval(-60*60*24*3),
                respondedAt: Date().addingTimeInterval(-60*60*12)
            ),
            Invitation(
                id: UUID().uuidString,
                eventId: "1", 
                inviterId: "user1",
                inviteeId: "user4",
                inviteeName: "Sophie Bernard",
                inviteeEmail: "sophie@example.com",
                inviteePhotoURL: nil,
                status: .declined,
                message: "Tu me manques !",
                sentAt: Date().addingTimeInterval(-60*60*24*4),
                respondedAt: Date().addingTimeInterval(-60*60*24)
            )
        ]
    }
}
