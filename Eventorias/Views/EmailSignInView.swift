//
//  EmailSignInView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI
import Firebase
import FirebaseStorage
import PhotosUI

struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    @State private var isSignUp = false
    @State private var showImagePicker = false
    @State private var selectedImage: UIImage? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond noir pour harmoniser avec ProfileView
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 30) {
                    // En-tête
                    headerView
                    
                    // Champs de formulaire
                    formFields
                    
                    // Boutons d'action
                    actionButtons
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(false)
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
            .alert("Erreur", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage)
            }
            .onChange(of: viewModel.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
            .onAppear {
                viewModel.loadStoredCredentials()
            }
            .sheet(isPresented: $showImagePicker) {
                PhotosPicker(
                    selection: Binding<PhotosPickerItem?>(get: { nil }, set: { newValue in
                        if let newValue {
                            Task {
                                if let data = try? await newValue.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    DispatchQueue.main.async {
                                        self.selectedImage = image
                                        self.viewModel.profileImage = image
                                    }
                                }
                            }
                        }
                    }),
                    matching: .images
                ) {
                    Text("Sélectionner une photo")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color("Red"))
                        .cornerRadius(10)
                        .padding()
                }
                .presentationBackground(Color.black)
                .presentationDetents([.medium])
            }
        }
    }
    
    // MARK: - Components
    
    private var headerView: some View {
        HStack {
            Text(isSignUp ? "Créer un compte" : "Se connecter")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
        }
    }
    
    private var formFields: some View {
        VStack(spacing: 25) {
            // Champs spécifiques au mode création de compte
            if isSignUp {
                // Sélection photo de profil
                VStack(spacing: 15) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        if let image = selectedImage ?? viewModel.profileImage {
                            // Afficher l'image sélectionnée
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                        } else {
                            // Afficher une image par défaut ou un placeholder
                            ZStack {
                                Circle()
                                    .fill(Color("DarkGry"))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: "person.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 40, height: 40)
                                    .foregroundColor(.gray)
                                
                                Image(systemName: "plus.circle.fill")
                                    .resizable()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(Color("Red"))
                                    .background(Color.black)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
                                    .offset(x: 35, y: 35)
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    Text(selectedImage == nil ? "Ajouter une photo" : "Modifier la photo")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color("Red"))
                }
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity, alignment: .center)
                
                // Champ nom d'utilisateur
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nom d'utilisateur")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gray)
                    
                    StyledTextField(placeholder: "Entrez votre nom d'utilisateur", text: $viewModel.username, accessibilityId: "Champ nom d'utilisateur")
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .textContentType(.username)
                        .accessibilityLabel("Champ nom d'utilisateur")
                }
            }
            
            // Champ email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                StyledTextField(placeholder: "Entrez votre email", text: $viewModel.email, accessibilityId: "Champ email")
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .textContentType(.emailAddress)
                    .accessibilityLabel("Champ email")
                    .accessibilityHint("Saisissez votre adresse email")
            }
            
            // Champ mot de passe
            VStack(alignment: .leading, spacing: 8) {
                Text("Mot de passe")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                StyledPasswordField(password: $viewModel.password)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 20) {
            // Bouton principal
            Button(action: handleAuthentication) {
                HStack {
                    if viewModel.isLoading || viewModel.isUploadingImage {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSignUp ? "Créer un compte" : "Se connecter")
                        .font(.headline)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isFormValid ? Color("Red") : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!isFormValid || viewModel.isLoading || viewModel.isUploadingImage)
            
            // Lien pour basculer entre connexion et inscription
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Déjà un compte ? Se connecter" : "Pas de compte ? S'inscrire")
                    .foregroundColor(.white)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.top, 10)
    }
    
    private func handleAuthentication() {
        // Mettre à jour l'image de profil dans le ViewModel
        if isSignUp {
            viewModel.profileImage = selectedImage
        }
        
        Task {
            if isSignUp {
                await viewModel.signUp()
            } else {
                await viewModel.signIn()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        if isSignUp {
            return viewModel.isSignUpFormValid
        } else {
            return viewModel.isFormValid
        }
    }
}

// MARK: - Styled Password Field

struct StyledPasswordField: View {
    @Binding var password: String
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack(alignment: .trailing) {
            if isPasswordVisible {
                TextField("Entrez votre mot de passe", text: $password)
                    .padding(.horizontal, 16)
                    .padding(.trailing, 50) // Espace pour l'icône
                    .frame(height: 56)
                    .background(Color("DarkGry"))
                    .cornerRadius(5)
                    .foregroundColor(.white)
                    .textContentType(.password)
                    .accessibilityIdentifier("Champ mot de passe")
            } else {
                SecureField("Entrez votre mot de passe", text: $password)
                    .padding(.horizontal, 16)
                    .padding(.trailing, 50) // Espace pour l'icône
                    .frame(height: 56)
                    .background(Color("DarkGry"))
                    .cornerRadius(5)
                    .foregroundColor(.white)
                    .textContentType(.password)
                    .accessibilityIdentifier("Champ mot de passe")
            }
            
            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundColor(.white)
                    .padding(.trailing, 16)
            }
            .accessibilityIdentifier(isPasswordVisible ? "Masquer le mot de passe" : "Afficher le mot de passe")
        }
        .accessibilityLabel("Champ mot de passe")
        .accessibilityHint("Saisissez votre mot de passe")
    }
}

#Preview {
    EmailSignInView()
        .environmentObject(AuthenticationViewModel())
}
