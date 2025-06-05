//
// AuthenticationViewModel.swift
// Eventorias
//
// Created by TLiLi Hamdi on 27/05/2025.
//

import Foundation
import SwiftUI
import Firebase
import FirebaseAuth

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// État d'authentification de l'utilisateur pour l'UI
    @Published var isAuthenticated = false
    
    /// État de chargement des opérations
    @Published var isLoading = false
    
    /// Message d'erreur à afficher
    @Published var errorMessage = ""
    
    /// Contrôle l'affichage de l'alerte d'erreur
    @Published var showingError = false
    
    /// Email saisi par l'utilisateur
    @Published var email = ""
    
    /// Mot de passe saisi par l'utilisateur
    @Published var password = ""
    
    // MARK: - Private Properties
    
    /// Service d'authentification
    private let authService: AuthenticationService
    
    /// Service Keychain pour le stockage sécurisé des identifiants
    private let keychainService = KeychainService()
    
    /// Indique si l'utilisateur est réellement authentifié dans Firebase
    private var isUserLoggedIn: Bool {
        authService.isUserAuthenticated()
    }
    
    /// Clé UserDefaults pour contrôler l'affichage de l'écran de connexion
    private let showLoginScreenKey = "showLoginScreen"
    
    /// Clés pour le stockage sécurisé des identifiants
    private let emailKeychainKey = "userEmail"
    private let passwordKeychainKey = "userPassword"
    
    // MARK: - Computed Properties
    
    /// Vérifie si le formulaire est valide
    var isFormValid: Bool {
        authService.isValidEmail(email) && authService.isValidPassword(password)
    }
    
    /// Indique si on a un utilisateur Firebase mais qu'on affiche quand même l'écran de connexion
    /// ou si des identifiants ont été précédemment sauvegardés
    var hasStoredCredentials: Bool {
        (isUserLoggedIn && !isAuthenticated) || keychainService.exists(for: emailKeychainKey)
    }
    
    // MARK: - Initialization
    
    init(authService: AuthenticationService = AuthenticationService()) {
        self.authService = authService
        checkAuthenticationStatus()
    }
    
    // MARK: - Private Methods
    
    /// Vérifie le statut d'authentification au démarrage
    private func checkAuthenticationStatus() {
        // Par défaut, on affiche l'écran de connexion même si l'utilisateur est authentifié
        isAuthenticated = UserDefaults.standard.bool(forKey: showLoginScreenKey)
    }
    
    /// Exécute une action d'authentification avec gestion d'erreur
    /// - Parameter action: L'action d'authentification à exécuter
    private func performAuthAction(_ action: () async throws -> AuthDataResult) async {
        isLoading = true
        errorMessage = ""
        showingError = false
        
        do {
            _ = try await action()
            isAuthenticated = true
            // Enregistrer que l'utilisateur a été authentifié manuellement
            UserDefaults.standard.set(true, forKey: showLoginScreenKey)
            clearForm()
        } catch {
            handleAuthError(error)
        }
        
        isLoading = false
    }
    
    /// Gère les erreurs d'authentification
    /// - Parameter error: L'erreur à traiter
    private func handleAuthError(_ error: Error) {
        if let authError = error as? AuthErrorCode {
            switch authError.code {
            case .userNotFound:
                errorMessage = "Aucun compte trouvé avec cet email."
            case .wrongPassword:
                errorMessage = "Mot de passe incorrect."
            case .emailAlreadyInUse:
                errorMessage = "Un compte existe déjà avec cet email."
            case .weakPassword:
                errorMessage = "Le mot de passe est trop faible."
            case .invalidEmail:
                errorMessage = "Format d'email invalide."
            default:
                errorMessage = error.localizedDescription
            }
        } else {
            errorMessage = error.localizedDescription
        }
        showingError = true
    }
    
    /// Vide le formulaire
    private func clearForm() {
        email = ""
        password = ""
    }
    
    // MARK: - Public Methods
    
    /// Connecte l'utilisateur
    func signIn() async {
        // Sauvegarder les identifiants temporairement pour pouvoir les utiliser après l'authentification
        let emailToStore = self.email
        let passwordToStore = self.password
        
        await performAuthAction {
            try await authService.signIn(email: emailToStore, password: passwordToStore)
        }
        
        // Stocker les identifiants de manière sécurisée après une connexion réussie
        if isAuthenticated {
            storeCredentialsExplicit(email: emailToStore, password: passwordToStore)
        }
    }
    
    /// Crée un nouveau compte utilisateur
    func signUp() async {
        // Sauvegarder les identifiants temporairement pour pouvoir les utiliser après l'authentification
        let emailToStore = self.email 
        let passwordToStore = self.password
        
        await performAuthAction {
            try await authService.signUp(email: emailToStore, password: passwordToStore)
        }
        
        // Stocker les identifiants après une inscription réussie
        if isAuthenticated {
            storeCredentialsExplicit(email: emailToStore, password: passwordToStore)
        }
    }
    
    /// Déconnecte l'utilisateur et vide le formulaire (pour déconnexion manuelle)
    func signOut() {
        signOutWithoutClearingForm()
        clearForm()
    }
    
    /// Déconnecte l'utilisateur sans vider le formulaire (pour déconnexion automatique)
    func signOutWithoutClearingForm() {
        do {
            try authService.signOut()
            isAuthenticated = false
            // Réinitialiser la préférence de l'écran de connexion
            UserDefaults.standard.set(false, forKey: showLoginScreenKey)
        } catch {
            handleAuthError(error)
        }
    }
    
    /// Utilise les informations d'authentification stockées pour une connexion rapide
    func quickSignIn() {
        if isUserLoggedIn {
            isAuthenticated = true
            UserDefaults.standard.set(true, forKey: showLoginScreenKey)
        }
    }
    
    /// Ferme l'alerte d'erreur
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    /// Stocke les identifiants de l'utilisateur de façon sécurisée dans le Keychain
    private func storeCredentials() {
        storeCredentialsExplicit(email: self.email, password: self.password)
    }
    
    /// Stocke des identifiants spécifiques de façon sécurisée dans le Keychain
    private func storeCredentialsExplicit(email: String, password: String) {
        // Vérifier que les identifiants ne sont pas vides
        guard !email.isEmpty && !password.isEmpty else {
            return
        }
        
        // Supprimer d'abord les identifiants existants pour éviter des conflits
        _ = keychainService.delete(for: emailKeychainKey)
        _ = keychainService.delete(for: passwordKeychainKey)
        
        // Attendre un peu pour s'assurer que la suppression est terminée
        Thread.sleep(forTimeInterval: 0.1)
        
        // Stocker l'email et le mot de passe dans le Keychain
        _ = keychainService.save(email, for: emailKeychainKey)
        _ = keychainService.save(password, for: passwordKeychainKey)
        
        // Mettre à jour les champs actuels pour réfléter les valeurs stockées
        DispatchQueue.main.async {
            self.email = email
            self.password = password
        }
    }
    
    /// Force le stockage d'identifiants de test pour débogage
    func forceStoreTestCredentials() {
        let testEmail = "test@example.com"
        let testPassword = "password123"
        
        // Supprimer d'abord les identifiants existants pour éviter des conflits
        _ = keychainService.delete(for: emailKeychainKey)
        _ = keychainService.delete(for: passwordKeychainKey)
        
        // Attendre un peu pour s'assurer que la suppression est terminée
        Thread.sleep(forTimeInterval: 0.1)
        
        // Stocker les nouveaux identifiants
        _ = keychainService.save(testEmail, for: emailKeychainKey)
        _ = keychainService.save(testPassword, for: passwordKeychainKey)
        
        // Mettre à jour les champs immédiatement
        DispatchQueue.main.async {
            self.email = testEmail
            self.password = testPassword
        }
    }
    
    /// Charge les identifiants stockés s'ils existent
    func loadStoredCredentials() {
        // Vérifier si des identifiants existent dans le Keychain
        let hasCredentials = keychainService.exists(for: emailKeychainKey)
        
        // En développement, utiliser des identifiants de test seulement si aucun identifiant personnel n'existe
        #if DEBUG
        if !hasCredentials {
            forceStoreTestCredentials()
            return
        }
        #endif
        
        if hasCredentials {
            if let storedEmail = keychainService.retrieve(for: emailKeychainKey),
               let storedPassword = keychainService.retrieve(for: passwordKeychainKey),
               !storedEmail.isEmpty && !storedPassword.isEmpty {
                
                // Forcer la mise à jour sur le thread principal
                DispatchQueue.main.async {
                    self.email = storedEmail
                    self.password = storedPassword
                }
            } else {
                // Les identifiants sont vides ou invalides, forcer des identifiants de test
                forceStoreTestCredentials()
            }
        } else {
            // Aucun identifiant trouvé, forcer des identifiants de test
            forceStoreTestCredentials()
        }
    }
    

}
