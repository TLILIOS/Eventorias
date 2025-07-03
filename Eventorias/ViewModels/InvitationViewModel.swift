//
//  InvitationViewModel.swift
//  Eventorias
//
//  Created on 03/07/2025
//

import Foundation
import SwiftUI
import Combine
import FirebaseFirestore

// Définir les méthodes et propriétés requises sans exiger ObservableObject
protocol InvitationViewModelProtocol {
    var eventInvitations: [Invitation] { get }
    var isLoading: Bool { get }
    var errorMessage: String { get }
    
    func loadInvitations(for eventId: String) async
    func createInvitation(eventId: String, inviteeId: String, inviteeName: String, email: String?, message: String?) async throws
    func updateInvitationStatus(invitation: Invitation, newStatus: InvitationStatus) async throws
    func removeInvitation(invitation: Invitation) async throws
    func canRespondToInvitation(_ invitation: Invitation) -> Bool
}

// Classe de base abstraite compatible avec SwiftUI ObservableObject
@MainActor
class AbstractInvitationViewModel: ObservableObject, @preconcurrency InvitationViewModelProtocol {
    @Published var eventInvitations: [Invitation] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    func loadInvitations(for eventId: String) async {
        fatalError("loadInvitations(for:) doit être implémentée par les sous-classes")
    }
    
    func createInvitation(eventId: String, inviteeId: String, inviteeName: String, email: String?, message: String?) async throws {
        fatalError("createInvitation(eventId:inviteeId:inviteeName:email:message:) doit être implémentée par les sous-classes")
    }
    
    func updateInvitationStatus(invitation: Invitation, newStatus: InvitationStatus) async throws {
        fatalError("updateInvitationStatus(invitation:newStatus:) doit être implémentée par les sous-classes")
    }
    
    func removeInvitation(invitation: Invitation) async throws {
        fatalError("removeInvitation(invitation:) doit être implémentée par les sous-classes")
    }
    
    func canRespondToInvitation(_ invitation: Invitation) -> Bool {
        fatalError("canRespondToInvitation(_:) doit être implémentée par les sous-classes")
    }
}

@MainActor
final class InvitationViewModel: AbstractInvitationViewModel {
    // MARK: - Published Properties
    
    // MARK: - Private Properties
    private let firestoreService: FirestoreServiceProtocol
    private let authService: AuthenticationServiceProtocol
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(firestoreService: FirestoreServiceProtocol, authService: AuthenticationServiceProtocol) {
        self.firestoreService = firestoreService
        self.authService = authService
    }
    
    // MARK: - Public Methods
    override func loadInvitations(for eventId: String) async {
        isLoading = true
        errorMessage = ""
        
        do {
            // Récupérer les invitations depuis Firestore
            let invitations = try await firestoreService.getEventInvitations(eventId: eventId)
            self.eventInvitations = invitations
            isLoading = false
        } catch {
            errorMessage = "Impossible de charger les invitations: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    override func createInvitation(eventId: String, inviteeId: String, inviteeName: String, email: String? = nil, message: String? = nil) async throws {
        guard let currentUserId = authService.currentUser?.uid else {
            throw NSError(domain: "InvitationViewModel", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"])
        }
        
        let invitation = Invitation.create(
            eventId: eventId,
            inviterId: currentUserId,
            inviteeId: inviteeId,
            inviteeName: inviteeName,
            inviteeEmail: email,
            message: message
        )
        
        // Sauvegarder l'invitation dans Firestore
        try await firestoreService.createInvitation(invitation)
        
        // Ajouter à notre tableau local pour la mise à jour de l'interface
        eventInvitations.append(invitation)
    }
    
    override func updateInvitationStatus(invitation: Invitation, newStatus: InvitationStatus) async throws {
        guard let invitationId = invitation.id, let index = eventInvitations.firstIndex(where: { $0.id == invitationId }) else {
            throw NSError(domain: "InvitationViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invitation introuvable"])
        }
        
        var updatedInvitation = invitation
        
        switch newStatus {
        case .accepted:
            updatedInvitation = invitation.accepted()
        case .declined:
            updatedInvitation = invitation.declined()
        case .pending:
            updatedInvitation.status = .pending
        }
        
        // Mettre à jour l'invitation dans Firestore
        try await firestoreService.updateInvitation(updatedInvitation)
        
        // Mettre à jour notre tableau local pour refléter le changement dans l'UI
        eventInvitations[index] = updatedInvitation
    }
    
    override func removeInvitation(invitation: Invitation) async throws {
        guard let invitationId = invitation.id else {
            throw NSError(domain: "InvitationViewModel", code: 404, userInfo: [NSLocalizedDescriptionKey: "ID d'invitation invalide"])
        }
        
        // Supprimer l'invitation de Firestore
        try await firestoreService.deleteInvitation(invitationId)
        
        // Mettre à jour notre tableau local pour refléter la suppression dans l'UI
        eventInvitations.removeAll { $0.id == invitationId }
    }
    
    // MARK: - Helper Methods
    func canEditInvitation(_ invitation: Invitation) -> Bool {
        // Vérifier si l'utilisateur actuel est l'organisateur de l'événement
        return invitation.inviterId == authService.currentUser?.uid
    }
    
    override func canRespondToInvitation(_ invitation: Invitation) -> Bool {
        // Vérifier si l'utilisateur actuel est l'invité
        return invitation.inviteeId == authService.currentUser?.uid && invitation.status == .pending
    }
}

// Note: La classe MockInvitationViewModel est désormais définie dans InvitationListView.swift pour éviter les redéclarations
