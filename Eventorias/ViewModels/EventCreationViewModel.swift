//
//  EventCreationViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//
import SwiftUI
import Combine
import Photos
import AVFoundation
import UIKit

@MainActor
final class EventCreationViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var eventTitle: String = ""
    @Published var eventDescription: String = "" 
    @Published var eventDate: Date = Date()
    @Published var eventAddress: String = ""
    @Published var eventCategory: EventCategory = .other
    @Published var eventImage: UIImage?
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var imageUploadState: ImageUploadState = .idle
    @Published var eventCreationSuccess = false
    @Published var errorMessage = ""
    @Published var imageURL: String = ""
    @Published var cameraPermissionGranted = false
    @Published var photoLibraryPermissionGranted = false
    
    // Stocke le nom de l'image en cours d'upload pour la vérification ultérieure
    private var imageName: String = ""
    
    // MARK: - Dependencies injectées
    private let eventViewModel: AnyEventViewModel
    private let authService: AuthenticationServiceProtocol
    private let storageService: StorageServiceProtocol
    private let firestoreService: FirestoreServiceProtocol
    
    // MARK: - Initialization avec injection de dépendance pure
    init(
        eventViewModel: AnyEventViewModel,
        authService: AuthenticationServiceProtocol,
        storageService: StorageServiceProtocol,
        firestoreService: FirestoreServiceProtocol
    ) {
        self.eventViewModel = eventViewModel
        self.authService = authService
        self.storageService = storageService
        self.firestoreService = firestoreService
    }
    
    // MARK: - Image Upload State (inchangé)
        enum ImageUploadState: Equatable {
            case idle
            case uploading(Double)
            case success
            case failure
            
            static func ==(lhs: ImageUploadState, rhs: ImageUploadState) -> Bool {
                switch (lhs, rhs) {
                case (.idle, .idle), (.success, .success), (.failure, .failure):
                    return true
                case (.uploading(let lhsProgress), .uploading(let rhsProgress)):
                    return lhsProgress == rhsProgress
                default:
                    return false
                }
            }
        }
    
    // MARK: - Methods
    @MainActor
    func createEvent() async -> Bool {
        // Validation des champs requis
        let trimmedTitle = eventTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedAddress = eventAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedTitle.isEmpty {
            errorMessage = "Veuillez saisir un titre pour l'événement"
            return false
        }
        
        if trimmedAddress.isEmpty {
            errorMessage = "Veuillez saisir une adresse pour l'événement"
            return false
        }
        
        // Réinitialisation des erreurs
        errorMessage = ""
        
        // Vérification que l'utilisateur est bien authentifié avant de commencer
        guard let _ = authService.getCurrentUser(), authService.isUserAuthenticated() else {
            errorMessage = "Vous devez être connecté pour créer un événement"
            return false
        }
        
        // Capturer les informations d'utilisateur avant les opérations
        let organizer = authService.currentUserDisplayName
        let organizerEmail = authService.currentUserEmail ?? "email@non-renseigne.com"
        
        // Upload de l'image si elle existe
        if let image = eventImage {
            do {
                try await uploadImage(image)
                
                // Vérification supplémentaire: l'URL d'image a-t-elle été correctement définie?
                if imageURL.isEmpty {
                    print("⚠️ DEBUG: URL d'image vide après uploadImage réussi")
                    throw NSError(domain: "EventCreation", code: 1003,
                                userInfo: [NSLocalizedDescriptionKey: "URL d'image non disponible après upload"])
                }
                
                // Vérification optionnelle: le fichier existe-t-il réellement?
                do {
                    print("⚠️ DEBUG: Vérification de l'existence du fichier uploadé")
                    let _ = try await storageService.getDownloadURL(for: "event_images/" + imageName)
                    print("⚠️ DEBUG: Fichier vérifié et disponible!")
                } catch {
                    print("⚠️ DEBUG: Échec de vérification du fichier: \(error.localizedDescription)")
                    throw NSError(domain: "EventCreation", code: 1004,
                                userInfo: [NSLocalizedDescriptionKey: "Le fichier uploadé n'est pas accessible"])
                }
                
            } catch let urlError as URLError {
                let errorMsg = handleNetworkError(urlError)
                errorMessage = "Erreur réseau: \(errorMsg)"
                imageUploadState = .failure
                return false
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSURLErrorDomain {
                    let errorMsg = handleNetworkError(error)
                    errorMessage = "Erreur réseau: \(errorMsg)"
                } else {
                    errorMessage = "Erreur lors de l'upload de l'image: \(error.localizedDescription)"
                }
                
                imageUploadState = .failure
                return false
            }
        }
        
        // Créer le nouvel événement en utilisant les services injectés
        do {
            let newEvent = Event(
                id: UUID().uuidString,
                title: trimmedTitle,
                description: eventDescription.isEmpty ? "Aucune description" : eventDescription,  // ✅ Valeur par défaut si vide
                date: eventDate,
                location: trimmedAddress,
                organizer: organizer,
                organizerImageURL: nil,
                imageURL: imageURL,
                category: .music,
                tags: ["Nouvel événement"],
                createdAt: Date()
            )
            
            try await firestoreService.createEvent(newEvent)
            
            print("✅ Événement créé avec succès")
            eventCreationSuccess = true
            return true
            
        } catch let urlError as URLError {
            let errorMsg = handleNetworkError(urlError)
            errorMessage = "Erreur réseau lors de la création de l'événement: \(errorMsg)"
            return false
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                let errorMsg = handleNetworkError(error)
                errorMessage = "Erreur réseau lors de la création de l'événement: \(errorMsg)"
            } else {
                errorMessage = "Erreur lors de la création de l'événement: \(error.localizedDescription)"
            }
            return false
        }
    }
    
    // MARK: - Permission Methods
    func checkCameraPermission() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.cameraPermissionGranted = granted
                    if !granted {
                        self?.errorMessage = "Accès à la caméra refusé"
                    }
                }
            }
        case .authorized:
            cameraPermissionGranted = true
            errorMessage = ""
        case .denied, .restricted:
            cameraPermissionGranted = false
            errorMessage = "Accès à la caméra refusé. Veuillez autoriser l'accès dans les Réglages."
        @unknown default:
            cameraPermissionGranted = false
            errorMessage = "Statut d'autorisation inconnu"
        }
    }
    
    func checkPhotoLibraryPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch photoAuthorizationStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in
                DispatchQueue.main.async {
                    self?.photoLibraryPermissionGranted = (status == .authorized)
                    if status != .authorized {
                        self?.errorMessage = "Accès aux photos refusé"
                    }
                }
            }
        case .authorized:
            photoLibraryPermissionGranted = true
            errorMessage = ""
        case .denied, .restricted:
            photoLibraryPermissionGranted = false
            errorMessage = "Accès aux photos refusé. Veuillez autoriser l'accès dans les Réglages."
        case .limited:
            photoLibraryPermissionGranted = true
            errorMessage = ""
        @unknown default:
            photoLibraryPermissionGranted = false
            errorMessage = "Statut d'autorisation inconnu"
        }
    }
    
    func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                print("Settings opened: \(success)")
            })
        }
    }
    
    /// Génère un message d'erreur convivial pour les erreurs réseau
    func handleNetworkError(_ error: Error) -> String {
        let nsError = error as NSError
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                return "Aucune connexion Internet. Vérifiez vos paramètres réseau."
            case .timedOut:
                return "La requête a expiré. Vérifiez votre connexion et réessayez."
            case .networkConnectionLost:
                return "La connexion réseau a été perdue. Vérifiez votre connexion et réessayez."
            case .cannotFindHost, .cannotConnectToHost:
                return "Impossible de se connecter au serveur. Réessayez plus tard."
            case .dataNotAllowed:
                return "L'accès aux données est restreint. Vérifiez les paramètres de votre forfait de données."
            default:
                return "Erreur réseau (code: \(urlError.code.rawValue)). Réessayez plus tard."
            }
        }
        
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case -1001: // kCFURLErrorTimedOut
                return "La requête a expiré. Vérifiez votre connexion et réessayez."
            case -1003: // kCFURLErrorCannotFindHost
                return "Hôte introuvable. Vérifiez votre connexion et réessayez."
            case -1004: // kCFURLErrorCannotConnectToHost
                return "Impossible de se connecter au serveur. Réessayez plus tard."
            case -1005: // kCFURLErrorNetworkConnectionLost
                return "La connexion réseau a été perdue lors de l'opération. Vérifiez votre connexion puis réessayez."
            case -1009: // kCFURLErrorNotConnectedToInternet
                return "Pas de connexion Internet. Vérifiez vos paramètres réseau."
            case -1020: // kCFURLErrorCannotLoadFromNetwork
                return "Impossible de charger depuis le réseau. Vérifiez votre connexion."
            default:
                return "Erreur réseau (code: \(nsError.code)). Réessayez plus tard."
            }
        }
        
        if nsError.domain == "FIRStorageErrorDomain" {
            switch nsError.code {
            case -13010: // Object not found
                return "Le fichier n'existe pas ou est inaccessible."
            case -13040: // Network error occurred
                return "Une erreur réseau s'est produite pendant l'upload/download."
            default:
                return "Erreur de stockage (code: \(nsError.code)). Réessayez plus tard."
            }
        }
        
        return "Erreur de connexion. Vérifiez votre réseau et réessayez."
    }
    
    @MainActor
    func uploadImage(_ image: UIImage) async throws {
        print("⚠️ DEBUG: Début uploadImage")
        
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            let error = NSError(domain: "EventCreationViewModel", code: 1001,
                              userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image en données JPEG"])
            print("⚠️ DEBUG: Échec de compression d'image: \(error)")
            throw error
        }
        
        guard !imageData.isEmpty else {
            let error = NSError(domain: "EventCreationViewModel", code: 1002,
                              userInfo: [NSLocalizedDescriptionKey: "Données d'image vides"])
            print("⚠️ DEBUG: Données d'image vides")
            throw error
        }
        
        print("⚠️ DEBUG: Taille des données d'image: \(imageData.count) octets")
        imageUploadState = .uploading(0.0)
        
        imageName = UUID().uuidString + ".jpg"
        let imagePath = "event_images/" + imageName
        print("⚠️ DEBUG: Chemin d'image généré: \(imagePath)")
        
        do {
            let maxRetries = 2
            var currentRetry = 0
            var lastError: Error? = nil
            
            while currentRetry <= maxRetries {
                do {
                    imageUploadState = .uploading(0.2 + Double(currentRetry) * 0.1)
                    print("⚠️ DEBUG: Tentative d'upload \(currentRetry + 1)/\(maxRetries + 1)")
                    
                    let metadataAdapter = FirebaseStorageMetadataAdapter()
                    metadataAdapter.contentType = "image/jpeg"
                    
                    imageUploadState = .uploading(0.5)
                    
                    let downloadURL = try await storageService.uploadImage(imageData, path: imagePath, metadata: metadataAdapter)
                    print("⚠️ DEBUG: URL de téléchargement reçue: \(downloadURL)")
                    
                    self.imageURL = downloadURL
                    imageUploadState = .success
                    print("⚠️ DEBUG: Upload réussi, état mis à jour à .success")
                    return
                    
                } catch let urlError as URLError where urlError.code == .networkConnectionLost || urlError.code == .timedOut {
                    lastError = urlError
                    currentRetry += 1
                    print("⚠️ DEBUG: Erreur réseau lors de l'upload (tentative \(currentRetry)/\(maxRetries + 1)): \(urlError.localizedDescription)")
                    
                    if currentRetry <= maxRetries {
                        print("⚠️ DEBUG: Nouvelle tentative dans 1 seconde...")
                        try await Task.sleep(nanoseconds: 1_000_000_000)
                        continue
                    }
                    throw urlError
                } catch {
                    print("⚠️ DEBUG: Erreur non liée au réseau lors de l'upload: \(error.localizedDescription)")
                    throw error
                }
            }
            
            if let lastError = lastError {
                throw lastError
            }
            
            throw NSError(domain: "EventCreationViewModel", code: 1010,
                        userInfo: [NSLocalizedDescriptionKey: "Échec après plusieurs tentatives d'upload"])
        } catch {
            print("⚠️ DEBUG: Erreur finale lors de l'upload: \(error.localizedDescription)")
            imageUploadState = .failure
            throw error
        }
    }
    
    func resetForm() {
        eventTitle = ""  // ✅ Correction: vide au lieu de "New event"
        eventDescription = ""  // ✅ Correction: vide au lieu de placeholder
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .idle
        eventCreationSuccess = false
        errorMessage = ""
        imageURL = ""
    }
}
