//
//  ProfileViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import FirebaseAuth
import Combine
import FirebaseStorage

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
    
    private let authViewModel: any AuthenticationViewModelProtocol
    
    // MARK: - Initialization
    
    init(authViewModel: any AuthenticationViewModelProtocol) {
        self.authViewModel = authViewModel
        loadUserProfile()
    }
    
    // MARK: - Methods
    
    /// Charge les informations du profil de l'utilisateur à partir de Firebase Auth
    func loadUserProfile() {
        isLoading = true
        
        if let user = Auth.auth().currentUser {
            displayName = user.displayName ?? "Non défini"
            email = user.email ?? ""
            
            if let photoURL = user.photoURL {
                avatarUrl = photoURL
                print("📷 DEBUG: Photo URL trouvée: \(photoURL)")
            } else {
                print("⚠️ DEBUG: Aucune photo URL trouvée pour l'utilisateur")
                // Tenter de récupérer l'image depuis Storage en utilisant l'UID
                let storageRef = FirebaseStorage.Storage.storage().reference().child("profile_images/\(user.uid).jpg")
                Task {
                    do {
                        let downloadURL = try await storageRef.downloadURL()
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
    
    /// Met à jour le nom d'affichage de l'utilisateur
    /// - Parameter newName: Nouveau nom d'affichage
    func updateDisplayName(_ newName: String) async {
        guard !newName.isEmpty else { 
            errorMessage = "Display name cannot be empty"
            return 
        }
        
        isLoading = true
        
        let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest()
        changeRequest?.displayName = newName
        
        do {
            try await changeRequest?.commitChanges()
            DispatchQueue.main.async {
                self.displayName = newName
                self.isLoading = false
                self.errorMessage = ""
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to update display name: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
    
    /// Méthode pour déconnecter l'utilisateur
    func signOut() {
        do {
            try Auth.auth().signOut()
            authViewModel.signOut()
        } catch {
            errorMessage = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}
