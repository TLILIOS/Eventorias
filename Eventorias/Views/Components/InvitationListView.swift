//
//  InvitationListView.swift
//  Eventorias
//
//  Created on 03/07/2025
//

import SwiftUI

struct InvitationListView: View {
    @ObservedObject var viewModel: AbstractInvitationViewModel
    let eventId: String
    let isOrganizer: Bool
    
    @State private var showAddInvitationSheet = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // En-tête de section
            HStack {
                Text("Invités")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isOrganizer {
                    Button(action: {
                        showAddInvitationSheet = true
                    }) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.horizontal, 16)
            
            // Liste des invitations
            if viewModel.isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    Spacer()
                }
                .padding()
            } else if viewModel.eventInvitations.isEmpty {
                HStack {
                    Spacer()
                    Text("Aucun invité pour le moment")
                        .foregroundColor(.gray)
                    Spacer()
                }
                .padding()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 12) {
                        ForEach(viewModel.eventInvitations) { invitation in
                            InvitationCard(
                                invitation: invitation,
                                isOrganizer: isOrganizer,
                                canRespond: viewModel.canRespondToInvitation(invitation),
                                onAccept: {
                                    Task {
                                        try? await viewModel.updateInvitationStatus(invitation: invitation, newStatus: .accepted)
                                    }
                                },
                                onDecline: {
                                    Task {
                                        try? await viewModel.updateInvitationStatus(invitation: invitation, newStatus: .declined)
                                    }
                                },
                                onRemove: {
                                    Task {
                                        try? await viewModel.removeInvitation(invitation: invitation)
                                    }
                                }
                            )
                            .frame(width: 140)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.loadInvitations(for: eventId)
            }
        }
        .sheet(isPresented: $showAddInvitationSheet) {
            AddInvitationView(viewModel: viewModel, eventId: eventId)
                .presentationDetents([.medium, .large])
        }
    }
}

struct InvitationCard: View {
    let invitation: Invitation
    let isOrganizer: Bool
    let canRespond: Bool
    let onAccept: () -> Void
    let onDecline: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Photo ou initiales
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                if let photoURL = invitation.inviteePhotoURL {
                    AsyncImage(url: URL(string: photoURL)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .clipShape(Circle())
                        } else {
                            Text(String(invitation.inviteeName.prefix(1)))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 60, height: 60)
                } else {
                    Text(String(invitation.inviteeName.prefix(1)))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                
                // Badge de statut
                if invitation.status != .pending {
                    Image(systemName: invitation.status.icon)
                        .foregroundColor(Color(invitation.status.colorName))
                        .background(Circle().fill(Color.black))
                        .padding(4)
                        .offset(x: 20, y: -20)
                }
            }
            
            // Nom
            Text(invitation.inviteeName)
                .font(.callout)
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.tail)
            
            // Statut
            Text(invitation.status.rawValue)
                .font(.caption)
                .foregroundColor(Color(invitation.status.colorName))
            
            // Actions
            if canRespond {
                HStack {
                    Button(action: onAccept) {
                        Image(systemName: "checkmark")
                            .foregroundColor(.green)
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    
                    Button(action: onDecline) {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .padding(4)
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                }
            } else if isOrganizer && invitation.status == .pending {
                Button(action: onRemove) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .padding(4)
                        .background(Color.black.opacity(0.5))
                        .clipShape(Circle())
                }
            }
        }
        .padding(8)
        .background(Color("DarkGray"))
        .cornerRadius(12)
    }
}

// MARK: - Class pour Preview
class MockInvitationViewModel: AbstractInvitationViewModel {
    override init() {
        super.init()
        self.eventInvitations = [
            Invitation(id: "1", eventId: "event1", inviterId: "org1", inviteeId: "user1", inviteeName: "Sophie Martin", status: .pending, sentAt: Date()),
            Invitation(id: "2", eventId: "event1", inviterId: "org1", inviteeId: "user2", inviteeName: "Thomas Dubois", status: .accepted, sentAt: Date())
        ]
    }
    
    override func loadInvitations(for eventId: String) async {
        // Ne rien faire, les données sont déjà chargées
    }
    
    override func createInvitation(eventId: String, inviteeId: String, inviteeName: String, email: String?, message: String?) async throws {
        // Simuler la création
        let newInvitation = Invitation.create(
            eventId: eventId,
            inviterId: "currentUser",
            inviteeId: inviteeId,
            inviteeName: inviteeName,
            inviteeEmail: email,
            message: message
        )
        eventInvitations.append(newInvitation)
    }
    
    override func updateInvitationStatus(invitation: Invitation, newStatus: InvitationStatus) async throws {
        // Simuler la mise à jour
        if let index = eventInvitations.firstIndex(where: { $0.id == invitation.id }) {
            var updated = invitation
            updated.status = newStatus
            eventInvitations[index] = updated
        }
    }
    
    override func removeInvitation(invitation: Invitation) async throws {
        // Simuler la suppression
        eventInvitations.removeAll { $0.id == invitation.id }
    }
    
    override func canRespondToInvitation(_ invitation: Invitation) -> Bool {
        return invitation.status == .pending
    }
}

// MARK: - Previews
#Preview {
    InvitationListView(
        viewModel: MockInvitationViewModel(),
        eventId: "example-event",
        isOrganizer: true
    )
    .background(Color.black)
}
