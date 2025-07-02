//
// AuthenticationComponents.swift
// Eventorias
//
// Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI

// MARK: - Reusable Components

/// Section pour la saisie de l'email
struct EmailSection: View {
    @Binding var email: String
    
    var body: some View {
        Section(header: Text("Email")) {
            TextField("Entrez votre email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .textContentType(.emailAddress)
                .accessibilityLabel("Champ email")
                .accessibilityHint("Saisissez votre adresse email")
        }
    }
}

struct PasswordSection: View {
    @Binding var password: String
    @State private var isPasswordVisible = false
    
    var body: some View {
        Section(header: Text("Mot de passe")) {
            HStack {
                if isPasswordVisible {
                    TextField("Entrez votre mot de passe", text: $password)
                        .textContentType(.password)
                        .accessibilityLabel("Champ mot de passe")
                        .accessibilityHint("Saisissez votre mot de passe")
                } else {
                    SecureField("Entrez votre mot de passe", text: $password)
                        .textContentType(.password)
                        .accessibilityLabel("Champ mot de passe")
                        .accessibilityHint("Saisissez votre mot de passe")
                }
                
                Button(action: {
                    isPasswordVisible.toggle()
                }) {
                    Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                        .foregroundColor(.blue)
                }
                .accessibilityLabel(isPasswordVisible ? "Masquer le mot de passe" : "Afficher le mot de passe")
            }
        }
    }
}

/// Section pour les actions d'authentification
struct ActionSection: View {
    @Binding var isSignUp: Bool
    let isFormValid: Bool
    let isLoading: Bool
    let action: () -> Void
    
    var body: some View {
        Section {
            Button(action: action) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    }
                    
                    Text(isSignUp ? "Créer un compte" : "Se connecter")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!isFormValid || isLoading)
            .accessibilityLabel(isSignUp ? "Bouton créer un compte" : "Bouton se connecter")
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Déjà un compte ? Se connecter" : "Pas de compte ? S'inscrire")
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Basculer entre connexion et inscription")
        }
    }
}

/// Vue principale d'authentification
struct AuthenticationView: View {
    @StateObject private var viewModel = AppDependencyContainer.shared.makeAuthenticationViewModel()
    
    // Computed property for form validation
    private var isFormValid: Bool {
        !viewModel.email.isEmpty && viewModel.password.count >= 6
    }
    
    var body: some View {
        NavigationView {
            Form(content: {
                EmailSection(email: $viewModel.email)
                PasswordSection(password: $viewModel.password)
                ActionSection(
                    isSignUp: .constant(false), // No sign-up functionality in current ViewModel
                    isFormValid: isFormValid,
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.signIn()
                    }
                }
            })
            .navigationTitle("Connexion")
            .alert("Erreur", isPresented: .init(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.dismissError() })) {
                Button("OK") {
                    viewModel.dismissError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "Une erreur s'est produite")
            }
        }
    }
}

#Preview {
    AuthenticationView()
}
