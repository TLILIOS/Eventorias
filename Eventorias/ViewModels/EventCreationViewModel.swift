//
//  EventCreationViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import Combine
import FirebaseStorage
import FirebaseFirestore
import FirebaseAuth
import Photos
import AVFoundation
import UIKit

/// ViewModel responsable de la gestion de la création d'événements
@MainActor
final class EventCreationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    // Form values
    @Published var eventTitle: String = "New event"
    @Published var eventDescription: String = "Tap here to enter your description"
    @Published var eventDate: Date = Date()
    @Published var eventAddress: String = ""
    @Published var eventImage: UIImage?
    
    // UI state
    @Published var showingAlert = false
    @Published var alertTitle = ""
    @Published var alertMessage = ""
    @Published var imageUploadState: ImageUploadState = .idle
    @Published var eventCreationSuccess = false
    @Published var errorMessage = ""
    @Published var imageURL: String = ""
    @Published var cameraPermissionGranted = false
    @Published var photoLibraryPermissionGranted = false
    
    // MARK: - Dependencies
    
    private let eventViewModel: EventViewModel
    
    // Firebase Storage
    private let storage = Storage.storage()
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    
    init(eventViewModel: EventViewModel) {
        self.eventViewModel = eventViewModel
        
        // Les vérifications d'autorisations seront effectuées à la demande
        // pour éviter de provoquer des dialogues système lors de l'initialisation
    }
    
    // MARK: - Image Upload State
    
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
    
    /// Crée un nouvel événement avec les valeurs actuelles
    /// - Returns: Un booléen indiquant si la création a réussi
    @MainActor
    func createEvent() async -> Bool {
        print("⚠️ DEBUG: Début createEvent - Thread: \(Thread.current.isMainThread ? "Main" : "Background")")
        // Validation des champs requis
        if eventTitle.isEmpty {
            errorMessage = "Veuillez saisir un titre pour l'événement"
            return false
        }
        
        if eventAddress.isEmpty {
            errorMessage = "Veuillez saisir une adresse pour l'événement"
            return false
        }
        
        // Réinitialisation des erreurs
        errorMessage = ""
        imageUploadState = .idle
        
        // Upload de l'image si elle existe
        print("⚠️ DEBUG: Image présente pour upload: \(eventImage != nil)")
        if let image = eventImage {
            do {
                // Tenter d'uploader l'image d'abord
                try await uploadImage(image)
            } catch {
                errorMessage = "Erreur lors de l'upload de l'image: \(error.localizedDescription)"
                imageUploadState = .failure
                return false
            }
        }
        
        // Créer le nouvel événement
        do {
            // Créer un document dans Firestore
            let eventRef = db.collection("events").document()
            
            // Obtenir l'utilisateur connecté pour l'organisateur (si disponible)
            let auth = Auth.auth()
            let organizer = auth.currentUser?.displayName ?? "Utilisateur anonyme"
            let organizerEmail = auth.currentUser?.email
            
            // Créer le modèle d'événement conforme à notre modèle Event
            let newEvent = Event(
                id: eventRef.documentID,
                title: eventTitle,
                description: eventDescription,
                date: eventDate,
                location: eventAddress,  // utilise eventAddress comme location
                organizer: organizer,     // nom de l'utilisateur connecté
                organizerImageURL: nil,   // pas d'image de l'organisateur pour l'instant
                imageURL: imageURL,       // URL de l'image uploadée sur Firebase Storage
                category: "Général",      // catégorie par défaut
                tags: ["Nouvel événement"],  // tag par défaut
                createdAt: Date()         // date de création actuelle
            )
            
            // Enregistrer dans Firestore
            try await eventRef.setData(from: newEvent)
            
            // Mettre à jour l'état
            eventCreationSuccess = true
            return true
        } catch {
            errorMessage = "Erreur lors de la création de l'événement: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Réinitialise les valeurs du formulaire
    func resetForm() {
        eventTitle = "New event"
        eventDescription = "Tap here to enter your description"
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .idle
        eventCreationSuccess = false
        errorMessage = ""
    }
    
    /// Upload une image sur Firebase Storage avec suivi de progression
    /// - Parameter image: UIImage à uploader
    @MainActor
    func uploadImage(_ image: UIImage) async throws {
        print("⚠️ DEBUG: Début de la méthode uploadImage")
        
        // Vérifier que l'image est valide
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            print("❌ DEBUG: Impossible de convertir l'image en données JPEG")
            throw NSError(domain: "EventCreationViewModel", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image en données JPEG"])
        }
        
        // Vérifier que les données ne sont pas vides
        guard !imageData.isEmpty else {
            print("❌ DEBUG: Données d'image vides")
            throw NSError(domain: "EventCreationViewModel", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Données d'image vides"])
        }
        
        // Mise à jour de l'état initial
        imageUploadState = .uploading(0.0)
        
        // Utiliser un UUID sans tirets pour éviter des problèmes potentiels de chemin
        let imageName = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".jpg"
        let imagePath = "event_images/"
        let fullPath = imagePath + imageName
        
        print("📁 DEBUG: Chemin complet du fichier: \(fullPath)")
        
        // Créer la référence Storage
        let storageRef = storage.reference().child(fullPath)
        
        // Créer les métadonnées pour l'image
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        do {
            // Mettre en place un Task pour suivre la progression
            let progressTask = Task {
                // Créer un uploadTask pour suivre la progression
                let uploadTask = storageRef.putData(imageData, metadata: metadata)
                
                // Observer la progression et mettre à jour l'UI
                uploadTask.observe(.progress) { [weak self] snapshot in
                    guard let self = self, let progress = snapshot.progress else { return }
                    let percentComplete = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                    
                    Task { @MainActor in
                        self.imageUploadState = .uploading(percentComplete)
                        print("📤 Upload: \(Int(percentComplete * 100))%")
                    }
                }
            }
            
            print("⚠️ DEBUG: Démarrage de l'upload avec putDataAsync")
            
            // IMPORTANT: Utiliser putDataAsync qui attend automatiquement la fin de l'upload
            // avant de continuer l'exécution du code
            try await storageRef.putDataAsync(imageData, metadata: metadata)
            
            // L'upload est maintenant terminé
            print("✅ DEBUG: Upload complètement terminé avec putDataAsync")
            print("💾 DEBUG: Fichier uploadé à: \(storageRef.fullPath)")
            
            // Annuler le task de progression car l'upload est terminé
            progressTask.cancel()
            
            // Tenter de récupérer l'URL de téléchargement avec une logique de nouvelle tentative
            let downloadURL = try await getDownloadURLWithRetries(for: storageRef, retries: 3, delay: .seconds(1))

            print("✅ DEBUG: URL obtenue avec succès: \(downloadURL.absoluteString)")

            // Mise à jour du modèle avec l'URL
            self.imageURL = downloadURL.absoluteString
            self.imageUploadState = .success
            print("🏁 Upload réussi et URL récupérée: \(downloadURL.absoluteString)")
            
            // Mise à jour du modèle avec l'URL
            self.imageURL = downloadURL.absoluteString
            self.imageUploadState = .success
            print("🏁 Upload réussi et URL récupérée: \(downloadURL.absoluteString)")
            
            return
        } catch {
            print("❌ DEBUG: Erreur lors de l'upload: \(error.localizedDescription)")
            imageUploadState = .failure
            throw error
        }
    }
    /// Tente de récupérer l'URL de téléchargement avec plusieurs tentatives en cas d'échec.
    private func getDownloadURLWithRetries(for ref: StorageReference, retries: Int, delay: Duration) async throws -> URL {
        var lastError: Error?
        for attempt in 0..<retries {
            do {
                print("📍 DEBUG: Tentative \(attempt + 1) de récupération de l'URL...")
                return try await ref.downloadURL()
            } catch let error as NSError where error.code == StorageErrorCode.objectNotFound.rawValue {
                print("⚠️ DEBUG: Objet non trouvé, nouvelle tentative dans \(delay.description)...")
                lastError = error
                try await Task.sleep(for: delay)
            } catch {
                // Pour toute autre erreur, échouer immédiatement
                throw error
            }
        }
        // Si toutes les tentatives échouent, lancer la dernière erreur connue
        throw lastError ?? NSError(domain: "EventCreationViewModel", code: 1003, userInfo: [NSLocalizedDescriptionKey: "Impossible de récupérer l'URL de téléchargement après \(retries) tentatives."])
    }

    // MARK: - Gestion des permissions
    
    /// Ouvre les réglages de l'application pour permettre à l'utilisateur de modifier les autorisations
    func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
    
    /// Vérifie et demande l'autorisation d'accès à la galerie de photos
    func checkPhotoLibraryPermission() {
        let status = PHPhotoLibrary.authorizationStatus()
        handlePhotoLibraryAuthorizationStatus(status)
    }
    
    /// Gère l'état d'autorisation de la galerie de photos
    private func handlePhotoLibraryAuthorizationStatus(_ status: PHAuthorizationStatus) {
        print("⚠️ DEBUG: État permission photothèque: \(status)")
        switch status {
        case .authorized, .limited:
            photoLibraryPermissionGranted = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] newStatus in
                DispatchQueue.main.async {
                    switch newStatus {
                    case .authorized, .limited:
                        self?.photoLibraryPermissionGranted = true
                    case .denied, .restricted:
                        self?.photoLibraryPermissionGranted = false
                        self?.errorMessage = "L'accès à vos photos est requis pour sélectionner une image. Vous pouvez modifier ce paramètre dans les Réglages."
                    case .notDetermined:
                        self?.photoLibraryPermissionGranted = false
                    @unknown default:
                        self?.photoLibraryPermissionGranted = false
                    }
                }
            }
        case .denied, .restricted:
            photoLibraryPermissionGranted = false
            errorMessage = "L'accès à vos photos est requis pour sélectionner une image. Vous pouvez modifier ce paramètre dans les Réglages."
        @unknown default:
            photoLibraryPermissionGranted = false
        }
    }
    
    /// Vérifie et demande l'autorisation d'accès à la caméra
    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        handleCameraAuthorizationStatus(status)
    }
    
    /// Gère l'état d'autorisation de la caméra
    private func handleCameraAuthorizationStatus(_ status: AVAuthorizationStatus) {
        print("⚠️ DEBUG: État permission caméra: \(status)")
        switch status {
        case .authorized:
            cameraPermissionGranted = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.cameraPermissionGranted = granted
                    if !granted {
                        self?.errorMessage = "L'accès à la caméra est requis pour prendre une photo. Vous pouvez modifier ce paramètre dans les Réglages."
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionGranted = false
            errorMessage = "L'accès à la caméra est requis pour prendre une photo. Vous pouvez modifier ce paramètre dans les Réglages."
        @unknown default:
            cameraPermissionGranted = false
        }
    }
}
