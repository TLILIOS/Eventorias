//
//  SignIn.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//

import SwiftUI
import Firebase
import FirebaseAuth

// MARK: - Authentication Manager
@MainActor
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    
    func signIn(email: String, password: String) async {
        await performAuthAction {
            try await Auth.auth().signIn(withEmail: email, password: password)
        }
    }
    
    func signUp(email: String, password: String) async {
        await performAuthAction {
            try await Auth.auth().createUser(withEmail: email, password: password)
        }
    }
    
    private func performAuthAction(_ action: @escaping () async throws -> AuthDataResult) async {
        isLoading = true
        
        do {
            _ = try await action()
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    func signOut() {
        try? Auth.auth().signOut()
        isAuthenticated = false
    }
}

// MARK: - Sign In View
struct SignIn: View {
    @StateObject private var authManager = AuthenticationManager()
    @State private var showingEmailSignIn = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Fond noir
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack {
                    // Logo
                    VStack(spacing: 0) {
                        Image("Logo Eventorias")
                    }
                    .padding(.top, 200)
                    
                    Spacer(minLength: 80)
                    
                    // Sign in with email button
                    Button(action: {
                        showingEmailSignIn = true
                    }) {
                        HStack {
                            Image("Sign in with email")
                        }
                    }
                    .padding(.bottom, 300)

                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEmailSignIn) {
                EmailSignInView()
                    .environmentObject(authManager)
            }
            .alert("Error", isPresented: $authManager.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authManager.errorMessage)
            }
            .navigationDestination(isPresented: $authManager.isAuthenticated) {
                MainAppView()
            }
        }
    }
}

// MARK: - Email Sign In View
struct EmailSignInView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && !authManager.isLoading
    }
    
    var body: some View {
        NavigationStack {
            Form {
                EmailSection(email: $email)
                PasswordSection(password: $password)
                ActionSection(
                    isSignUp: $isSignUp,
                    isFormValid: isFormValid,
                    isLoading: authManager.isLoading,
                    action: handleAuthentication
                )
            }
            .navigationTitle(isSignUp ? "Create Account" : "Sign In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .disabled(authManager.isLoading)
            .alert("Error", isPresented: $authManager.showingError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(authManager.errorMessage)
            }
            .onChange(of: authManager.isAuthenticated) { _, isAuthenticated in
                if isAuthenticated {
                    dismiss()
                }
            }
        }
    }
    
    private func handleAuthentication() {
        Task {
            if isSignUp {
                await authManager.signUp(email: email, password: password)
            } else {
                await authManager.signIn(email: email, password: password)
            }
        }
    }
}

// MARK: - Reusable Components
struct EmailSection: View {
    @Binding var email: String
    
    var body: some View {
        Section(header: Text("Email")) {
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
        }
    }
}

struct PasswordSection: View {
    @Binding var password: String
    
    var body: some View {
        Section(header: Text("Password")) {
            SecureField("Password", text: $password)
        }
    }
}

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
                    
                    Text(isSignUp ? "Sign Up" : "Sign In")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
            }
            .disabled(!isFormValid)
            
            Button(action: { isSignUp.toggle() }) {
                Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Main App View (placeholder)
struct MainAppView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("You are signed in!")
                .font(.title)
            
            Button("Sign Out") {
                authManager.signOut()
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
}

#Preview {
    SignIn()
}
