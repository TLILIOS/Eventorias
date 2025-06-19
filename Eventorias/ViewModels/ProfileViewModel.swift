//
//  ProfileViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import Combine

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
    
    // MARK: - Initialization
    
    init(authViewModel: any AuthenticationViewModelProtocol, authService: AuthenticationServiceProtocol, storageService: StorageServiceProtocol) {
        self.authViewModel = authViewModel
        self.authService = authService
        self.storageService = storageService
        loadUserProfile()
    }
    
    // MARK: - Methods
    
    /// Charge les informations du profil de l'utilisateur à partir du service d'authentification
    func loadUserProfile() {
        isLoading = true
        
        if let user = authService.getCurrentUser() {
            // Récupérer les données utilisateur depuis l'adaptateur
            displayName = user.displayName ?? "Non défini"
            email = user.email ?? ""
            
            // Utiliser la méthode getPhotoURL() du protocole pour récupérer l'URL de la photo
            if let photoURL = user.getPhotoURL() {
                avatarUrl = photoURL
                print("📷 DEBUG: Photo URL trouvée: \(photoURL)")
            } else {
                print("⚠️ DEBUG: Aucune photo URL trouvée pour l'utilisateur")
                // Tenter de récupérer l'image depuis Storage en utilisant l'UID
                let imagePath = "profile_images/\(user.uid).jpg"
                Task {
                    do {
                        let downloadURL = try await storageService.getDownloadURL(for: imagePath)
                        DispatchQueue.main.async {
                            self.avatarUrl = downloadURL
                            print("📷 DEBUG: Photo URL récupérée depuis Storage: \(downloadURL)")
                        }
                    } catch {
                        print("⚠️ DEBUG: Impossible de récupérer l'URL de la photo depuis Storage: \(error.localizedDescription)")
                    }
                }
            }
        } else {
            errorMessage = "No user is currently logged in"
        }
        
        isLoading = false
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
        
        do {
            // Mise à jour du nom d'affichage via le service
            try await authService.updateUserProfile(displayName: name, photoURL: nil)
            
            // Mettre à jour l'état local
            self.displayName = name
            
            // Afficher un message de succès ou effectuer d'autres actions si nécessaire
        } catch {
            errorMessage = "Erreur lors de la mise à jour du nom d'affichage: \(error.localizedDescription)"
        }
    }
    
    /// Méthode pour déconnecter l'utilisateur
    func signOut() {
        do {
            try authService.signOut()
            authViewModel.signOut()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
