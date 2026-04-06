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
        let container = AppDependencyContainer.shared
        self._viewModel = StateObject(wrappedValue: container.makeAuthenticationViewModel())
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
            .task {
                await viewModel.loadStoredCredentialsAsync()
                hasLoadedCredentials = true
            }
            .onChange(of: viewModel.userIsLoggedIn) { _, isLoggedIn in
                if isLoggedIn {
                    // Fermer la sheet de connexion si elle est ouverte
                    showingEmailSignIn = false
                }
            }
        }
    }
}

#Preview {
    // Utiliser le container de dépendances pour le preview également
    SignInView()
}
