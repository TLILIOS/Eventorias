//
//  ProfileViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import FirebaseAuth
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
    
    private let authViewModel: AuthenticationViewModel
    
    // MARK: - Initialization
    
    init(authViewModel: AuthenticationViewModel) {
        self.authViewModel = authViewModel
        loadUserProfile()
    }
    
    // MARK: - Methods
    
    /// Charge les informations du profil de l'utilisateur à partir de Firebase Auth
    func loadUserProfile() {
        isLoading = true
        
        if let user = Auth.auth().currentUser {
            displayName = user.displayName ?? "User"
            email = user.email ?? "No email"
            
            if let photoURL = user.photoURL {
                avatarUrl = photoURL
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
