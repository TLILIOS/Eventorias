import Foundation
import SwiftUI
import UIKit

@MainActor
class AuthenticationViewModel: ObservableObject, AuthenticationViewModelProtocol {
    // Utilisé pour la liaison de données UI
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var profileImage: UIImage? = nil
    @Published var userIsLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // UserDefaults via AppStorage pour l'email
    private let lastEmailKey = "lastUserEmail"
    private let lastUsernameKey = "lastUsername"

    private let authenticationService: AuthenticationServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private let storageService: StorageServiceProtocol

    private let emailAccount = "userEmail"
    private let passwordAccount = "userPassword"

    init(authService: AuthenticationServiceProtocol, keychainService: KeychainServiceProtocol, storageService: StorageServiceProtocol) {
        self.authenticationService = authService
        self.keychainService = keychainService
        self.storageService = storageService
        self.userIsLoggedIn = authenticationService.isUserAuthenticated()
        
        // Initialiser les valeurs à partir de UserDefaults et Keychain directement dans l'initialisation
        if self.userIsLoggedIn == false {
            // Tentative de récupération de l'email depuis UserDefaults ou Keychain
            if let savedEmail = UserDefaults.standard.string(forKey: lastEmailKey) {
                self.email = savedEmail
            } else {
                // Si pas dans UserDefaults, essayer de récupérer depuis le keychain
                do {
                    let storedEmail = try keychainService.retrieve(for: emailAccount)
                    self.email = storedEmail
                } catch {
                    self.email = ""
                }
            }
            
            // Tentative de récupération du mot de passe depuis Keychain
            do {
                let storedPassword = try keychainService.retrieve(for: passwordAccount)
                self.password = storedPassword
            } catch {
                self.password = ""
            }
            
            // Récupération du nom d'utilisateur depuis UserDefaults
            if let savedUsername = UserDefaults.standard.string(forKey: lastUsernameKey) {
                self.username = savedUsername
            }
        }
    }

    func signIn() async {
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authenticationService.signIn(email: email, password: password)
            userIsLoggedIn = true
            storeCredentialsExplicit(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    func signUp() async {
        isLoading = true
        errorMessage = nil
        
        // Validation du nom d'utilisateur
        if username.isEmpty {
            errorMessage = "Le nom d'utilisateur est requis"
            isLoading = false
            return
        }
        
        do {
            // Création du compte utilisateur
            _ = try await authenticationService.signUp(email: email, password: password)
            
            // Mise à jour du profil utilisateur avec le nom d'utilisateur
            try await authenticationService.updateUserProfile(displayName: username, photoURL: nil)
            
            // Si une photo de profil est fournie, la télécharger
            print("📷 SignUp: profileImage est \(profileImage != nil ? "présente" : "nil")")
            if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.7) {
                print("📷 SignUp: Données image: \(imageData.count) octets")
                do {
                    guard let userId = authenticationService.getCurrentUser()?.uid else { throw NSError(domain: "Authentication", code: 401, userInfo: [NSLocalizedDescriptionKey: "Utilisateur non connecté"]) }

                    let imagePath = "profile_images/\(userId).jpg"
                    print("📷 SignUp: Upload vers \(imagePath)...")

                    let urlString = try await storageService.uploadImage(imageData, path: imagePath, metadata: nil)
                    print("📷 SignUp: Upload réussi, URL: \(urlString)")

                    guard let photoURL = URL(string: urlString) else { throw NSError(domain: "Storage", code: 400, userInfo: [NSLocalizedDescriptionKey: "URL invalide"]) }

                    try await authenticationService.updateUserProfile(displayName: nil, photoURL: photoURL)
                    print("📷 SignUp: Profil mis à jour avec photoURL")
                } catch {
                    print("❌ SignUp: Erreur upload photo: \(error)")
                }
            } else {
                print("📷 SignUp: Pas de photo à uploader")
            }
            
            userIsLoggedIn = true
            storeCredentialsExplicit(email: email, password: password)
            if !username.isEmpty {
                saveLastUsername(username)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func signOut() async {
        do {
            // Sauvegarder l'email avant la déconnexion
            saveLastEmail(email)
            if !username.isEmpty {
                saveLastUsername(username)
            }
            
            try authenticationService.signOut()
            userIsLoggedIn = false
            
            // Vider le mot de passe et l'email
            password = ""
            email = ""
            
            // Supprimer le mot de passe et l'email du keychain mais garder l'email dans UserDefaults
            // Les supprimer individuellement pour s'assurer que les deux sont bien supprimés
            try keychainService.delete(for: passwordAccount)
            try keychainService.delete(for: emailAccount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func storeCredentialsExplicit(email: String, password: String) {
        do {
            // Sauvegarder l'email dans UserDefaults et dans le Keychain
            saveLastEmail(email)
            try keychainService.save(email, for: emailAccount)
            
            // Sauvegarder le mot de passe dans le Keychain (plus sécurisé)
            try keychainService.save(password, for: passwordAccount)
        } catch {
            errorMessage = "Could not save credentials: \(error.localizedDescription)"
        }
    }
    
    // Méthodes pour sauvegarder et récupérer l'email dans UserDefaults
    private func saveLastEmail(_ email: String) {
        UserDefaults.standard.set(email, forKey: lastEmailKey)
    }
    
    private func saveLastUsername(_ username: String) {
        UserDefaults.standard.set(username, forKey: lastUsernameKey)
    }

    func loadStoredCredentials() {
        Task { @MainActor in
            await loadStoredCredentialsAsync()
        }
    }

    func loadStoredCredentialsAsync() async {
        // Charge l'email depuis UserDefaults ou Keychain
        if let savedEmail = UserDefaults.standard.string(forKey: lastEmailKey), !savedEmail.isEmpty {
            email = savedEmail
        } else {
            do {
                let storedEmail = try keychainService.retrieve(for: emailAccount)
                email = storedEmail
            } catch {
                // Pas d'email stocké, garder la valeur actuelle
            }
        }

        // Charge le mot de passe depuis le Keychain
        if password.isEmpty {
            do {
                let storedPassword = try keychainService.retrieve(for: passwordAccount)
                password = storedPassword
            } catch {
                // Pas de mot de passe stocké
            }
        }

        if let savedUsername = UserDefaults.standard.string(forKey: lastUsernameKey), !savedUsername.isEmpty {
            username = savedUsername
        }
    }
    
    func loadPasswordFromKeychain() {
        // Cette méthode ne doit être appelée que lorsqu'on est certain qu'il n'y a pas
        // d'interaction utilisateur en cours avec le champ de mot de passe
        do {
            let storedPassword = try keychainService.retrieve(for: passwordAccount)
            // Vérifier si l'utilisateur n'a pas déjà commencé à taper un mot de passe
            // Si le champ est vide, alors on peut mettre le mot de passe stocké
            if self.password.isEmpty {
                self.password = storedPassword
            }
        } catch {
            // Mot de passe non trouvé, ce qui est normal au premier lancement
            // Ne rien faire si l'utilisateur a déjà commencé à taper
            if self.password.isEmpty {
                self.password = ""
            }
        }
    }

    func quickSignIn() async {
        if !email.isEmpty && !password.isEmpty {
            await signIn()
        }
    }

    func signOutWithoutClearingForm() async {
        do {
            // Sauvegarder l'email et le username avant la déconnexion
            saveLastEmail(email)
            if !username.isEmpty {
                saveLastUsername(username)
            }
            
            try authenticationService.signOut()
            userIsLoggedIn = false
            
            // Ne pas supprimer les données du formulaire ni l'email du UserDefaults
            try keychainService.delete(for: passwordAccount)
            try keychainService.delete(for: emailAccount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func dismissError() {
        errorMessage = nil
    }
}
