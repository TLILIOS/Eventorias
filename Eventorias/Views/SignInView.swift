//
//  SignInView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI

struct SignInView: View {
    @StateObject private var viewModel: AuthenticationViewModel
    @State private var showingEmailSignIn = false
    @State private var hasLoadedCredentials = false
    
    init() {
        // Utiliser le container de dépendances pour créer le ViewModel
        let container = AppDependencyContainer.shared
        self._viewModel = StateObject(wrappedValue: container.makeAuthenticationViewModel())
        
        // Charger les identifiants avant le chargement de la vue
        let tempViewModel = container.makeAuthenticationViewModel()
        tempViewModel.loadStoredCredentials()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond noir
                Color.black.ignoresSafeArea(.all)
                
                VStack {
                    // Logo
                    VStack(spacing: 0) {
                        Image("Logo Eventorias")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 200)
                    }
                    .padding(.top, 100)
                    
                    Spacer(minLength: 80)
                    
                    // Sign in with email button
                    Button(action: {
                        // Charger les identifiants juste avant d'afficher l'écran de connexion
                        viewModel.loadStoredCredentials()
                        showingEmailSignIn = true
                    }) {
                        HStack {
                            Image("Sign in with email")
                                .resizable()
                                .scaledToFit()
                                .frame(height: 50)
                        }
                    }
                    .padding(.bottom, 20)
                    
                    // Espace en bas du bouton de connexion par email
                    Spacer().frame(height: 80)
                    
                    Spacer()
                }
                .padding()
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingEmailSignIn) {
                EmailSignInView()
                    .environmentObject(viewModel)
            }
            .alert("Error", isPresented: .init(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.dismissError() })) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
            .navigationDestination(isPresented: $viewModel.userIsLoggedIn) {
                EventList()
                    .environmentObject(viewModel)
            }
            .onAppear {
                viewModel.loadStoredCredentials()
                hasLoadedCredentials = true
            }
        }
    }
}

#Preview {
    // Utiliser le container de dépendances pour le preview également
    SignInView()
}
