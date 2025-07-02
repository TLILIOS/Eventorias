
import Foundation
import SwiftUI
import UIKit
@testable import Eventorias

/// Mock de AuthenticationViewModel utilisé pour les tests
final class MockAuthenticationViewModel: ObservableObject, AuthenticationViewModelProtocol {
    // Published properties pour l'interface utilisateur
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    @Published var profileImage: UIImage? = nil
    @Published var userIsLoggedIn = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // Services mockés nécessaires
    private let authService: AuthenticationServiceProtocol
    private let keychainService: KeychainServiceProtocol
    private let storageService: StorageServiceProtocol
    
    // Variables pour suivre les appels de méthodes (utile pour les tests)
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var storeCredentialsCalled = false
    var loadCredentialsCalled = false
    var quickSignInCalled = false
    var signOutWithoutClearingFormCalled = false
    var dismissErrorCalled = false
    
    // Variables pour contrôler le comportement des méthodes
    var shouldThrowError = false
    var mockError: Error = NSError(domain: "MockAuthError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée"])
    
    // Noms de comptes pour le keychain mock
    private let emailAccount = "userEmail"
    private let passwordAccount = "userPassword"
    
    init(
        authService: AuthenticationServiceProtocol? = nil,
        keychainService: KeychainServiceProtocol? = nil,
        storageService: StorageServiceProtocol? = nil
    ) {
        self.authService = authService ?? MockAuthenticationService()
        self.keychainService = keychainService ?? ViewModelMockKeychainService()
        self.storageService = storageService ?? ViewModelMockStorageService()
        self.userIsLoggedIn = self.authService.isUserAuthenticated()
    }

    
    @MainActor
    func signIn() async {
        signInCalled = true
        isLoading = true
        errorMessage = nil
        
        if shouldThrowError {
            errorMessage = mockError.localizedDescription
            isLoading = false
            return
        }
        
        do {
            _ = try await authService.signIn(email: email, password: password)
            userIsLoggedIn = true
            storeCredentialsExplicit(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func signUp() async {
        signUpCalled = true
        isLoading = true
        errorMessage = nil
        
        // Validation du nom d'utilisateur
        if username.isEmpty {
            errorMessage = "Le nom d'utilisateur est requis"
            isLoading = false
            return
        }
        
        if shouldThrowError {
            errorMessage = mockError.localizedDescription
            isLoading = false
            return
        }
        
        do {
            // Création du compte utilisateur
            _ = try await authService.signUp(email: email, password: password)
            
            // Mise à jour du profil utilisateur
            try await authService.updateUserProfile(displayName: username, photoURL: nil)
            
            // Si une photo de profil est fournie
            if let profileImage = profileImage, let imageData = profileImage.jpegData(compressionQuality: 0.7) {
                do {
                    guard let userId = authService.getCurrentUser()?.uid else { throw NSError(domain: "Authentication", code: 401) }
                    
                    let imagePath = "profile_images/\(userId).jpg"
                    let urlString = try await storageService.uploadImage(imageData, path: imagePath, metadata: nil)
                    
                    guard let photoURL = URL(string: urlString) else { throw NSError(domain: "Storage", code: 400) }
                    try await authService.updateUserProfile(displayName: nil, photoURL: photoURL)
                } catch {
                    print("Erreur lors du téléchargement de la photo de profil: \(error.localizedDescription)")
                }
            }
            
            userIsLoggedIn = true
            storeCredentialsExplicit(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    @MainActor
    func signOut() async {
        signOutCalled = true
        
        if shouldThrowError {
            errorMessage = mockError.localizedDescription
            return
        }
        
        do {
            try authService.signOut()
            userIsLoggedIn = false
            email = ""
            password = ""
            try keychainService.delete(for: emailAccount)
            try keychainService.delete(for: passwordAccount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func storeCredentialsExplicit(email: String, password: String) {
        storeCredentialsCalled = true
        
        if shouldThrowError {
            errorMessage = "Could not save credentials: \(mockError.localizedDescription)"
            return
        }
        
        do {
            try keychainService.save(email, for: emailAccount)
            try keychainService.save(password, for: passwordAccount)
        } catch {
            errorMessage = "Could not save credentials: \(error.localizedDescription)"
        }
    }
    
    func loadStoredCredentials() {
        loadCredentialsCalled = true
        
        if shouldThrowError {
            email = ""
            password = ""
            return
        }
        
        do {
            let storedEmail = try keychainService.retrieve(for: emailAccount)
            let storedPassword = try keychainService.retrieve(for: passwordAccount)
            self.email = storedEmail
            self.password = storedPassword
        } catch {
            self.email = ""
            self.password = ""
        }
    }
    
    @MainActor
    func quickSignIn() async {
        quickSignInCalled = true
        
        if !email.isEmpty && !password.isEmpty {
            await signIn()
        }
    }
    
    @MainActor
    func signOutWithoutClearingForm() async {
        signOutWithoutClearingFormCalled = true
        
        if shouldThrowError {
            errorMessage = mockError.localizedDescription
            return
        }
        
        do {
            try authService.signOut()
            userIsLoggedIn = false
            try keychainService.delete(for: emailAccount)
            try keychainService.delete(for: passwordAccount)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func dismissError() {
        dismissErrorCalled = true
        errorMessage = nil
    }
}

/// Mock pour le service de keychain pour tests de AuthViewModel
class ViewModelMockKeychainService: KeychainServiceProtocol {
    let service: String = "com.eventorias.mock.viewmodel"
    var storage: [String: String] = [:]
    var shouldThrowError = false
    
    func save(_ data: String, for account: String) throws {
        if shouldThrowError {
            throw NSError(domain: "KeychainError", code: 1)
        }
        storage[account] = data
    }
    
    func retrieve(for account: String) throws -> String {
        if shouldThrowError {
            throw NSError(domain: "KeychainError", code: 2)
        }
        
        guard let value = storage[account] else {
            throw NSError(domain: "KeychainError", code: 3)
        }
        
        return value
    }
    
    func delete(for account: String) throws {
        if shouldThrowError {
            throw NSError(domain: "KeychainError", code: 4)
        }
        storage.removeValue(forKey: account)
    }
    
    func update(_ data: String, for account: String) throws {
        if shouldThrowError {
            throw NSError(domain: "KeychainError", code: 5)
        }
        storage[account] = data
    }
    
    func exists(for account: String) -> Bool {
        return storage[account] != nil
    }
}

/// Mock pour le service de stockage
/// Mock pour le service de stockage pour tests de AuthViewModel
class ViewModelMockStorageService: StorageServiceProtocol {
    var shouldThrowError = false
    var mockDownloadURLString = "https://mock-storage.example.com/test-image.jpg"
    var mockDownloadURL: URL = URL(string: "https://mock-storage.example.com/test-image.jpg")!
    
    func uploadImage(_ imageData: Data, path: String, metadata: StorageMetadataProtocol?) async throws -> String {
        if shouldThrowError {
            throw NSError(domain: "StorageError", code: 1)
        }
        return "https://mock-storage.example.com/\(path)"
    }
    
    func getDownloadURL(for path: String) async throws -> URL {
        if shouldThrowError {
            throw NSError(domain: "StorageError", code: 2, userInfo: [NSLocalizedDescriptionKey: "URL non disponible"])
        }
        
        return mockDownloadURL
    }
}
