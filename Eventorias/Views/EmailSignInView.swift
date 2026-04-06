//
//  EmailSignInView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI
import PhotosUI

@MainActor
struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    @State private var isSignUpMode = false
    @State private var photoItem: PhotosPickerItem?
    @State private var localEmail = ""
    @State private var localPassword = ""
    @State private var localUsername = ""
    @State private var showError = false
    var backgroundColor: Color = Color("EventDarkGray")

    // Computed property for form validation
    private var isFormValid: Bool {
        !localEmail.isEmpty && localPassword.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond noir pour harmoniser avec ProfileView
                Color.black.edgesIgnoringSafeArea(.all)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // En-tête
                        headerView
                        
                        // Champs de formulaire
                        formFields
                        
                        // Boutons d'action
                        actionButtons
                        
                        // Espace supplémentaire pour éviter le chevauchement avec le clavier
                        Spacer()
                            .frame(height: 60)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
            .ignoresSafeArea(.keyboard)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .disabled(viewModel.isLoading)
                }
            }
            .disabled(viewModel.isLoading)
            .onChange(of: viewModel.errorMessage) { _, newError in
                showError = newError != nil
            }
            .alert("Erreur", isPresented: $showError) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                }
            }
            .task {
                await viewModel.loadStoredCredentialsAsync()
                localEmail = viewModel.email
                localPassword = viewModel.password
                localUsername = viewModel.username
            }
            .onChange(of: photoItem) { _, newItem in
            Task {
                if let newItem {
                    if let data = try? await newItem.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        viewModel.profileImage = image
                    }
                }
            }
        }

        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            Text(isSignUpMode ? "Créer un compte" : "Se connecter")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 25) {
            // Champ email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                StyledTextField(
                    placeholder: "Entrez votre email",
                    text: $localEmail,
                    keyboardType: .emailAddress,
                    textContentType: .emailAddress,
                    autocapitalization: .never,
                    disableAutocorrection: true,
                    accessibilityId: "Champ email",
                    accessibilityLabel: "Champ email",
                    accessibilityHint: "Saisissez votre adresse email"
                )
            }
            
            // Champ mot de passe
            VStack(alignment: .leading, spacing: 8) {
                Text("Mot de passe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                // Utilisation du StyledTextField original mais lié à l'état local
                StyledTextField(
                    placeholder: "Entrez votre mot de passe",
                    text: $localPassword, // Lié à l'état local au lieu du ViewModel
                    isSecure: true,
                    showPasswordToggle: true,
                    textContentType: nil, // Pas de textContentType pour éviter les interférences
                    accessibilityId: "Champ mot de passe"
                )
            }
            
            // Champs supplémentaires en mode inscription
            if isSignUpMode {
                // Champ nom d'utilisateur
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom d'utilisateur")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    StyledTextField(
                        placeholder: "Entrez votre nom d'utilisateur",
                        text: $localUsername,
                        textContentType: .username,
                        autocapitalization: .words,
                        disableAutocorrection: true,
                        accessibilityId: "Champ nom d'utilisateur"
                    )
                }
                
                // Photo de profil (optionnel)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Photo de profil (optionnel)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    // Utilisation d'un sélecteur d'image simple en attendant l'intégration complète
                    let currentProfileImage = viewModel.profileImage
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        HStack {
                            if let profileImage = currentProfileImage {
                                Image(uiImage: profileImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 80, height: 80)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                            } else {
                                Circle()
                                    .fill(backgroundColor)
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "person.crop.circle.fill")
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 40, height: 40)
                                            .foregroundColor(.gray)
                                    )
                            }
                            
                            Text("Sélectionner une photo")
                                .foregroundColor(Color("EventRed"))
                                .padding(.leading, 10)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if viewModel.profileImage != nil {
                        Button("Supprimer la photo") {
                            viewModel.profileImage = nil
                        }
                        .foregroundColor(.gray)
                        .padding(.top, 5)
                    }
                }
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            // Bouton principal
            Button(action: handleAuthentication) {
                HStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSignUpMode ? "S'inscrire" : "Se connecter")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color("EventRed") : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!isFormValid || viewModel.isLoading)
            
            // Bouton pour basculer entre connexion et création de compte
            Button(action: {
                isSignUpMode.toggle()
            }) {
                Text(isSignUpMode ? "Déjà un compte ? Se connecter" : "Nouvel utilisateur ? Créer un compte")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .underline()
            }
            .padding(.top, 5)
            .disabled(viewModel.isLoading)
        }
        .padding(.top, 10)
    }
    
    private func handleAuthentication() {
        let email = localEmail
        let password = localPassword
        let username = localUsername
        let signUp = isSignUpMode

        Task {
            await Task.yield()
            viewModel.email = email
            viewModel.password = password
            viewModel.username = username

            print("🔑 handleAuthentication: isSignUpMode=\(signUp), profileImage=\(viewModel.profileImage != nil)")

            if signUp {
                await viewModel.signUp()
            } else {
                await viewModel.signIn()
            }
        }
    }
}

#Preview {
    EmailSignInView()
        .environmentObject(AppDependencyContainer.shared.makeAuthenticationViewModel())
}
