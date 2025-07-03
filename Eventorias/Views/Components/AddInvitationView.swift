//
//  AddInvitationView.swift
//  Eventorias
//
//  Created on 03/07/2025
//

import SwiftUI

struct AddInvitationView: View {
    @ObservedObject var viewModel: AbstractInvitationViewModel
    let eventId: String
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var inviteeName = ""
    @State private var inviteeId = ""
    @State private var email = ""
    @State private var message = ""
    
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Inviter un participant")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding(.top)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom du participant")
                                .foregroundColor(.gray)
                            
                            TextField("", text: $inviteeName)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Identifiant Firebase (optionnel)")
                                .foregroundColor(.gray)
                            
                            TextField("", text: $inviteeId)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email (optionnel)")
                                .foregroundColor(.gray)
                            
                            TextField("", text: $email)
                                .textFieldStyle(.plain)
                                .padding(12)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message personnalisé (optionnel)")
                                .foregroundColor(.gray)
                            
                            TextEditor(text: $message)
                                .frame(minHeight: 100)
                                .padding(8)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(8)
                                .foregroundColor(.white)
                        }
                        
                        Button {
                            sendInvitation()
                        } label: {
                            HStack {
                                Spacer()
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Envoyer l'invitation")
                                        .bold()
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color("Red"))
                            .cornerRadius(10)
                            .foregroundColor(.white)
                        }
                        .disabled(inviteeName.isEmpty || isLoading)
                        .opacity(inviteeName.isEmpty ? 0.6 : 1)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Erreur"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    private func sendInvitation() {
        guard !inviteeName.isEmpty else { return }
        
        isLoading = true
        
        let finalInviteeId = inviteeId.isEmpty ? UUID().uuidString : inviteeId
        let finalEmail = email.isEmpty ? nil : email
        let finalMessage = message.isEmpty ? nil : message
        
        Task {
            do {
                try await viewModel.createInvitation(
                    eventId: eventId,
                    inviteeId: finalInviteeId,
                    inviteeName: inviteeName,
                    email: finalEmail,
                    message: finalMessage
                )
                
                // Retour au thread principal pour mettre à jour l'UI
                await MainActor.run {
                    isLoading = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Erreur lors de l'envoi de l'invitation: \(error.localizedDescription)"
                    showError = true
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    AddInvitationView(
        viewModel: MockInvitationViewModel(),
        eventId: "example-event-id"
    )
    .background(Color.black)
}
