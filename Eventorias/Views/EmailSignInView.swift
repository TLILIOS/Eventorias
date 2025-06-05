//
//  EmailSignInView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI
import Firebase

struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: AuthenticationViewModel
    
    @State private var isSignUp = false
    
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
            // Champ email
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gray)
                
                StyledTextField(placeholder: "Entrez votre email", text: $viewModel.email)
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
                    if viewModel.isLoading {
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
                .background(viewModel.isFormValid ? Color("Red") : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!viewModel.isFormValid || viewModel.isLoading)
            
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
        Task {
            if isSignUp {
                await viewModel.signUp()
            } else {
                await viewModel.signIn()
            }
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
            } else {
                SecureField("Entrez votre mot de passe", text: $password)
                    .padding(.horizontal, 16)
                    .padding(.trailing, 50) // Espace pour l'icône
                    .frame(height: 56)
                    .background(Color("DarkGry"))
                    .cornerRadius(5)
                    .foregroundColor(.white)
                    .textContentType(.password)
            }
            
            Button(action: {
                isPasswordVisible.toggle()
            }) {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                    .foregroundColor(.white)
                    .padding(.trailing, 16)
            }
        }
        .accessibilityLabel("Champ mot de passe")
        .accessibilityHint("Saisissez votre mot de passe")
    }
}

#Preview {
    EmailSignInView()
        .environmentObject(AuthenticationViewModel())
}
