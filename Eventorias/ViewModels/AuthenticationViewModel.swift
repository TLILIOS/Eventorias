//
// AuthenticationViewModel.swift
// Eventorias
//
// Created by TLiLi Hamdi on 27/05/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseStorage

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
    
    /// Nom d'utilisateur (uniquement pour l'inscription)
    @Published var username = ""
    
    /// Image de profil (uniquement pour l'inscription)
    @Published var profileImage: UIImage? = nil
    
    /// État d'upload de l'image
    @Published var isUploadingImage = false
    
    // MARK: - Private Properties
    
    /// Service d'authentification
    private let authService: AuthenticationServiceProtocol
    
    /// Service Keychain pour le stockage sécurisé des identifiants
    private let keychainService: KeychainServiceProtocol
    
    /// Service de stockage pour l'upload des images
    private let storageService: StorageServiceProtocol
    
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
        // Validation de base pour email et mot de passe
        let basicValidation = authService.isValidEmail(email) && authService.isValidPassword(password)
        
        // Pour l'inscription, vérifier aussi le nom d'utilisateur
        return basicValidation
    }
    
    /// Vérifie si le formulaire d'inscription est complet
    var isSignUpFormValid: Bool {
        let basicValidation = authService.isValidEmail(email) && authService.isValidPassword(password)
        return basicValidation && !username.isEmpty
    }
    
    /// Indique si on a un utilisateur Firebase mais qu'on affiche quand même l'écran de connexion
    /// ou si des identifiants ont été précédemment sauvegardés
    var hasStoredCredentials: Bool {
        (isUserLoggedIn && !isAuthenticated) || keychainService.exists(for: emailKeychainKey)
    }
    
    // MARK: - Initialization
    
    init(authService: AuthenticationServiceProtocol, keychainService: KeychainServiceProtocol, storageService: StorageServiceProtocol) {
        self.authService = authService
        self.keychainService = keychainService
        self.storageService = storageService
        checkAuthenticationStatus()
    }
    
    // MARK: - Private Methods
    
    /// Vérifie le statut d'authentification au démarrage
    func checkAuthenticationStatus() {
        // Vérifier si l'utilisateur est authentifié via le service d'authentification
        isAuthenticated = authService.isUserAuthenticated()
    }
    
    /// Exécute une action d'authentification avec gestion d'erreur
    /// - Parameter action: L'action d'authentification à exécuter
    private func performAuthAction(_ action: () async throws -> AuthDataResultProtocol) async {
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
    
    /// Gestion des erreurs d'authentification
    private func handleAuthError(_ error: Error) {
        // Gestion spécifique des erreurs Firebase
        if let nsError = error as NSError?, nsError.domain == "FIRAuthErrorDomain" {
            // Créer un AuthErrorCode à partir du code d'erreur NSError
            if let authErrorCode = AuthErrorCode(rawValue: nsError.code) {
                switch authErrorCode {
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
                case .tooManyRequests:
                    errorMessage = "Trop de tentatives. Veuillez réessayer plus tard."
                case .userDisabled:
                    errorMessage = "Ce compte a été désactivé."
                case .operationNotAllowed:
                    errorMessage = "Cette méthode d'authentification n'est pas autorisée."
                case .invalidCredential:
                    errorMessage = "Identifiants invalides."
                case .networkError:
                    errorMessage = "Erreur de connexion réseau."
                default:
                    errorMessage = error.localizedDescription
                }
            } else {
                errorMessage = error.localizedDescription
            }
        } else if let authError = error as? AuthErrorCode {
            // Gestion des erreurs AuthErrorCode directes (si utilisées ailleurs)
            switch authError {
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
        username = ""
        profileImage = nil
    }
    
    /// Upload l'image de profil et met à jour le profil utilisateur
    /// - Parameter completion: Callback appelé après completion avec succès (true) ou échec (false)
    func uploadProfileImageAndUpdateUser(completion: @escaping (Bool) -> Void) async {
        guard let currentUser = authService.getCurrentUser(), let image = profileImage else {
            completion(false)
            return
        }
        
        isUploadingImage = true
        
        do {
            // 1. Compresser l'image
            guard let imageData = image.jpegData(compressionQuality: 0.6) else {
                throw NSError(domain: "ImageCompression", code: 0, userInfo: [NSLocalizedDescriptionKey: "Échec de compression de l'image"])
            }
            
            // 2. Uploader l'image via le service de stockage
            let metadataAdapter = FirebaseStorageMetadataAdapter()
            metadataAdapter.contentType = "image/jpeg"
            
            let imagePath = "profile_images/\(currentUser.uid).jpg"
            let downloadURLString = try await storageService.uploadImage(imageData, path: imagePath, metadata: metadataAdapter)
            
            // 3. Mettre à jour le profil utilisateur via le service d'authentification
            guard let downloadURL = URL(string: downloadURLString) else {
                throw NSError(domain: "URLParsing", code: 0, userInfo: [NSLocalizedDescriptionKey: "URL invalide"])
            }
            
            try await authService.updateUserProfile(displayName: username, photoURL: downloadURL)
            
            DispatchQueue.main.async {
                self.isUploadingImage = false
                completion(true)
            }
        } catch {
            DispatchQueue.main.async {
                self.isUploadingImage = false
                self.errorMessage = "Échec de l'upload: \(error.localizedDescription)"
                self.showingError = true
                completion(false)
            }
        }
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
        let usernameToStore = self.username
        let profileImageToStore = self.profileImage
        
        await performAuthAction { try await authService.signUp(email: emailToStore, password: passwordToStore) }
        
        // Si l'inscription a réussi et qu'il y a une photo de profil ou un nom d'utilisateur
        if isAuthenticated && (profileImageToStore != nil || !usernameToStore.isEmpty) {
            // Mettre à jour le profil utilisateur avec le nom d'utilisateur et l'image
            if profileImageToStore != nil {
                await uploadProfileImageAndUpdateUser { _ in }
            } else if !usernameToStore.isEmpty {
                // Mettre à jour uniquement le nom d'utilisateur si pas d'image
                if let currentUser = Auth.auth().currentUser {
                    do {
                        let changeRequest = currentUser.createProfileChangeRequest()
                        changeRequest.displayName = usernameToStore
                        try await changeRequest.commitChanges()
                    } catch {
                        errorMessage = "Échec de mise à jour du profil: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
            
            // Stocker les identifiants dans le Keychain si l'authentification a réussi
            storeCredentialsExplicit(email: emailToStore, password: passwordToStore)
        } else if isAuthenticated {
            // Stocker les identifiants si l'authentification a réussi mais pas d'image ni de nom
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
        _ = try? keychainService.delete(for: emailKeychainKey)
        _ = try? keychainService.delete(for: passwordKeychainKey)
        
        // Attendre un peu pour s'assurer que la suppression est terminée
        Thread.sleep(forTimeInterval: 0.1)
        
        // Stocker l'email et le mot de passe dans le Keychain
        _ = try? keychainService.save(email, for: emailKeychainKey)
        _ = try? keychainService.save(password, for: passwordKeychainKey)
        
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
        _ = try? keychainService.delete(for: emailKeychainKey)
        _ = try? keychainService.delete(for: passwordKeychainKey)
        
        // Attendre un peu pour s'assurer que la suppression est terminée
        Thread.sleep(forTimeInterval: 0.1)
        
        // Stocker les nouveaux identifiants
        _ = try? keychainService.save(testEmail, for: emailKeychainKey)
        _ = try? keychainService.save(testPassword, for: passwordKeychainKey)
        
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
            if let storedEmail = try? keychainService.retrieve(for: emailKeychainKey),
               let storedPassword = try? keychainService.retrieve(for: passwordKeychainKey),
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
