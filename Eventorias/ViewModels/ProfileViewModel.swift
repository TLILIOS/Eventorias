//
//  ProfileViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import Combine
import FirebaseAuth

/// ViewModel responsable de la gestion des données et actions du profil utilisateur
@MainActor
final class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var displayName: String = ""
    @Published var email: String = ""
    @Published var avatarUrl: URL?
    @Published var notificationsEnabled: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    
    // MARK: - Dependencies
    
    private var authViewModel: any AuthenticationViewModelProtocol
    private let authService: AuthenticationServiceProtocol
    private let storageService: StorageServiceProtocol
    
    // Pour gérer les abonnements Combine
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(authViewModel: any AuthenticationViewModelProtocol, authService: AuthenticationServiceProtocol, storageService: StorageServiceProtocol) {
        print("📲 ProfileViewModel: Initialisation avec auth service")
        self.authViewModel = authViewModel
        self.authService = authService
        self.storageService = storageService
        
        // Au lieu de charger immédiatement, nous configurons un observateur
        setupAuthStateObserver()
    }
    
    // MARK: - Methods
    
    /// Configure un observateur pour les changements d'état d'authentification
    private func setupAuthStateObserver() {
        print("🔄 ProfileViewModel: Configuration de l'observateur d'état d'authentification")
        
        // Observer les changements d'état d'authentification via FirebaseAuth directement
        // Cela garantit que nous avons les dernières données utilisateur
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            guard let self = self else { return }
            
            print("🔄 ProfileViewModel: Changement d'état d'authentification détecté")
            if user != nil {
                // Un délai court pour s'assurer que les données Firebase sont complètement chargées
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.loadUserProfile()
                }
            } else {
                // Réinitialiser l'état du ViewModel quand l'utilisateur se déconnecte
                self.resetUserProfile()
            }
        }
    }
    
    /// Réinitialise les données du profil utilisateur
    private func resetUserProfile() {
        print("🧹 ProfileViewModel: Réinitialisation des données du profil")
        displayName = ""
        email = ""
        avatarUrl = nil
        errorMessage = ""
    }
    
    /// Charge les informations du profil de l'utilisateur à partir du service d'authentification
    func loadUserProfile() {
        print("📂 ProfileViewModel: Chargement du profil utilisateur")
        isLoading = true
        
        if let user = authService.getCurrentUser() {
            print("👤 ProfileViewModel: Utilisateur trouvé, UID: \(user.uid)")
            print("📋 ProfileViewModel: DisplayName brut: \(String(describing: user.displayName))")
            
            // Récupérer les données utilisateur depuis l'adaptateur
            displayName = user.displayName ?? "Non défini"
            email = user.email ?? ""
            
            // Utiliser la méthode getPhotoURL() du protocole pour récupérer l'URL de la photo
            if let photoURL = user.getPhotoURL() {
                avatarUrl = photoURL
                print("📷 ProfileViewModel: Photo URL trouvée: \(photoURL)")
            } else {
                print("⚠️ ProfileViewModel: Aucune photo URL dans l'objet utilisateur, tentative de récupération depuis Storage...")
                // Tenter de récupérer l'image depuis Storage en utilisant l'UID
                let imagePath = "profile_images/\(user.uid).jpg"
                print("🔍 ProfileViewModel: Recherche de l'image à: \(imagePath)")
                
                Task {
                    do {
                        let downloadURL = try await storageService.getDownloadURL(for: imagePath)
                        await MainActor.run {
                            self.avatarUrl = downloadURL
                            print("✅ ProfileViewModel: Photo URL récupérée depuis Storage: \(downloadURL)")
                        }
                    } catch {
                        await MainActor.run {
                            print("❌ ProfileViewModel: Impossible de récupérer l'URL de la photo depuis Storage: \(error.localizedDescription)")
                            // Essayer avec une autre extension
                            self.tryAlternativeImageFormats(userID: user.uid)
                        }
                    }
                }
            }
        } else {
            print("⚠️ ProfileViewModel: Aucun utilisateur connecté")
            errorMessage = "Aucun utilisateur n'est actuellement connecté"
        }
        
        isLoading = false
    }
    
    /// Essaie de récupérer l'image avec différents formats
    /// - Parameter userID: L'ID de l'utilisateur dont l'image de profil est recherchée
    /// - Returns: Task qui peut être attendue dans les tests
    @discardableResult
    private func tryAlternativeImageFormats(userID: String) -> Task<Void, Never> {
        let extensions = ["png", "jpeg", "jpg"]
        
        return Task {
            for ext in extensions {
                let imagePath = "profile_images/\(userID).\(ext)"
                print("🔍 ProfileViewModel: Essai avec l'extension \(ext): \(imagePath)")
                
                do {
                    let downloadURL = try await storageService.getDownloadURL(for: imagePath)
                    await MainActor.run {
                        self.avatarUrl = downloadURL
                        print("✅ ProfileViewModel: Photo trouvée avec extension \(ext): \(downloadURL)")
                    }
                    return
                } catch {
                    print("⚠️ ProfileViewModel: Échec avec extension \(ext): \(error.localizedDescription)")
                    // Continue avec la prochaine extension
                }
            }
            print("❌ ProfileViewModel: Aucune image trouvée pour l'utilisateur avec toutes les extensions testées")
        }
    }
    
    /// Méthode d'accessibilité pour les tests uniquement - expose tryAlternativeImageFormats
    /// - Parameter userID: L'ID de l'utilisateur dont l'image de profil est recherchée
    /// - Returns: Task qui peut être attendue dans les tests
    #if DEBUG
    @discardableResult
    func tryAlternativeImageFormatForTesting(userID: String) -> Task<Void, Never> {
        return tryAlternativeImageFormats(userID: userID)
    }
    #endif
    
    /// Met à jour les préférences de notifications
    /// - Parameter enabled: Booléen indiquant si les notifications doivent être activées
    func updateNotificationPreferences(enabled: Bool) {
        notificationsEnabled = enabled
        // Ici nous pourrions implémenter la logique pour sauvegarder ce paramètre dans Firestore
        // ou une autre base de données persistante
    }
    
    /// Met à jour la référence au AuthenticationViewModel
    /// - Parameter viewModel: Nouvelle référence au AuthenticationViewModel
    func updateAuthenticationViewModel(_ viewModel: any AuthenticationViewModelProtocol) {
        print("🔄 ProfileViewModel: Mise à jour de la référence AuthViewModel")
        self.authViewModel = viewModel
        
        // Recharger les données du profil après la mise à jour de la référence
        loadUserProfile()
    }
    
    /// Met à jour le nom d'affichage de l'utilisateur
    /// - Parameter name: Nouveau nom d'affichage
    func updateDisplayName(_ name: String) async {
        isLoading = true
        defer { isLoading = false }
        
        // Validation for empty display name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedName.isEmpty {
            errorMessage = "Display name cannot be empty"
            return
        }
        
        errorMessage = "" // Clear previous errors

        do {
            // Mise à jour du nom d'affichage via le service
            try await authService.updateUserProfile(displayName: trimmedName, photoURL: nil)
            
            // Mettre à jour l'état local en cas de succès
            self.displayName = trimmedName
        } catch {
            // Gérer l'erreur
            errorMessage = "Erreur lors de la mise à jour du nom d'affichage: \(error.localizedDescription)"
        }
    }
    
    /// Méthode pour déconnecter l'utilisateur
    func signOut() {
        do {
            try authService.signOut()
            Task {
                await authViewModel.signOut()
            }
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
