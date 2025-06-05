//
//  SignInView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI
import Firebase

struct SignInView: View {
    @StateObject private var viewModel = AuthenticationViewModel()
    @State private var showingEmailSignIn = false
    @State private var hasLoadedCredentials = false
    
    init() {
        // Créer une instance temporaire pour charger les identifiants avant même le chargement de la vue
        let tempViewModel = AuthenticationViewModel()
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
            .alert("Error", isPresented: $viewModel.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
            .navigationDestination(isPresented: $viewModel.isAuthenticated) {
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
    SignInView()
}
