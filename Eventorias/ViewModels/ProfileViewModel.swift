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
        
    }

    // MARK: - Methods
    
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

        // Recharger les données Firebase pour avoir les valeurs les plus récentes
        // (displayName et photoURL peuvent ne pas être à jour après un signUp)
        guard let firebaseUser = Auth.auth().currentUser else {
            print("⚠️ ProfileViewModel: Aucun utilisateur connecté")
            errorMessage = "Aucun utilisateur n'est actuellement connecté"
            isLoading = false
            return
        }

        let userId = firebaseUser.uid

        Task {
            do {
                try await firebaseUser.reload()
            } catch {
                print("⚠️ ProfileViewModel: Impossible de recharger le profil Firebase: \(error.localizedDescription)")
            }

            // Après reload, relire les valeurs depuis l'utilisateur rafraîchi
            guard let refreshedUser = Auth.auth().currentUser else {
                isLoading = false
                return
            }

            displayName = refreshedUser.displayName ?? "Non défini"
            email = refreshedUser.email ?? ""
            print("👤 ProfileViewModel: DisplayName: \(displayName), Email: \(email)")

            if let photoURL = refreshedUser.photoURL {
                avatarUrl = photoURL
                print("📷 ProfileViewModel: Photo URL trouvée: \(photoURL)")
                isLoading = false
            } else {
                // photoURL peut être nil si le signUp vient de finir et le cache Firebase
                // n'est pas encore synchronisé — retry après un délai
                print("⚠️ ProfileViewModel: photoURL nil, retry après délai...")
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                try? await firebaseUser.reload()

                if let retryUser = Auth.auth().currentUser, let photoURL = retryUser.photoURL {
                    avatarUrl = photoURL
                    print("📷 ProfileViewModel: Photo URL trouvée après retry: \(photoURL)")
                    isLoading = false
                    return
                }

                // Fallback : chercher directement dans Storage
                print("⚠️ ProfileViewModel: Toujours pas de photoURL, fallback Storage...")
                let imagePath = "profile_images/\(userId).jpg"

                do {
                    let downloadURL = try await storageService.getDownloadURL(for: imagePath)
                    self.avatarUrl = downloadURL
                    print("✅ ProfileViewModel: Photo URL récupérée depuis Storage: \(downloadURL)")
                } catch {
                    print("❌ ProfileViewModel: Impossible de récupérer l'URL de la photo: \(error.localizedDescription)")
                    self.tryAlternativeImageFormats(userID: userId)
                }
                isLoading = false
            }
        }
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
    
    /// Met à jour la photo de profil de l'utilisateur
    func updateProfilePhoto(_ image: UIImage) async {
        isLoading = true
        defer { isLoading = false }

        guard let firebaseUser = Auth.auth().currentUser else {
            errorMessage = "Aucun utilisateur connecté"
            return
        }

        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            errorMessage = "Impossible de convertir l'image"
            return
        }

        let imagePath = "profile_images/\(firebaseUser.uid).jpg"

        do {
            let urlString = try await storageService.uploadImage(imageData, path: imagePath, metadata: nil)
            print("📷 ProfileViewModel: Photo uploadée: \(urlString)")

            guard let photoURL = URL(string: urlString) else {
                errorMessage = "URL de photo invalide"
                return
            }

            try await authService.updateUserProfile(displayName: nil, photoURL: photoURL)
            self.avatarUrl = photoURL
            print("📷 ProfileViewModel: Profil mis à jour avec la photo")
        } catch {
            errorMessage = "Erreur lors de l'upload de la photo: \(error.localizedDescription)"
            print("❌ ProfileViewModel: Erreur upload photo: \(error)")
        }
    }

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
        self.authViewModel = viewModel
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
