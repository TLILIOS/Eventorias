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
    // MARK: - Published Properties (inchangées)
    @Published var eventTitle: String = "New event"
    @Published var eventDescription: String = "Tap here to enter your description"
    @Published var eventDate: Date = Date()
    @Published var eventAddress: String = ""
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

    // MARK: - Dependencies injectées
    private let eventViewModel: EventViewModelProtocol
    private let authService: AuthenticationServiceProtocol
    private let storageService: StorageServiceProtocol
    private let firestoreService: FirestoreServiceProtocol

    // MARK: - Initialization avec injection de dépendance pure
    init(
        eventViewModel: EventViewModelProtocol,
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

    // MARK: - Methods modifiées
    @MainActor
    func createEvent() async -> Bool {
        // Validation des champs requis (inchangée)
        if eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Veuillez saisir un titre pour l'événement"
            return false
        }
        
        if eventAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errorMessage = "Veuillez saisir une adresse pour l'événement"
            return false
        }
        
        // Réinitialisation des erreurs
        errorMessage = ""
        
        // Upload de l'image si elle existe
        if let image = eventImage {
            do {
                try await uploadImage(image)
            } catch {
                errorMessage = "Erreur lors de l'upload de l'image: \(error.localizedDescription)"
                imageUploadState = .failure
                return false
            }
        }
        
        // Créer le nouvel événement en utilisant les services injectés
        do {
            // ✅ Utilisation du service d'authentification injecté
            let organizer = authService.currentUserDisplayName
            let organizerEmail = authService.currentUserEmail ?? "email@non-renseigne.com"
            
            let newEvent = Event(
                id: UUID().uuidString, // ✅ Génération d'ID sans dépendance Firestore
                title: eventTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                description: eventDescription,
                date: eventDate,
                location: eventAddress.trimmingCharacters(in: .whitespacesAndNewlines),
                organizer: organizer,
                organizerImageURL: nil,
                imageURL: imageURL,
                category: "Général",
                tags: ["Nouvel événement"],
                createdAt: Date()
            )
            
            // ✅ Utilisation du service Firestore injecté
            try await firestoreService.createEvent(newEvent)
            eventCreationSuccess = true
            return true
            
        } catch {
            errorMessage = "Erreur lors de la création de l'événement: \(error.localizedDescription)"
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

    @MainActor
    func uploadImage(_ image: UIImage) async throws {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "EventCreationViewModel", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Impossible de convertir l'image en données JPEG"])
        }

        guard !imageData.isEmpty else {
            throw NSError(domain: "EventCreationViewModel", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Données d'image vides"])
        }

        imageUploadState = .uploading(0.0)

        let imageName = UUID().uuidString.replacingOccurrences(of: "-", with: "") + ".jpg"
        let imagePath = "event_images/" + imageName

        do {
            imageUploadState = .uploading(0.5) // Simulation progression
            
            // Utiliser l'adaptateur au lieu de StorageMetadata directement
            let metadataAdapter = FirebaseStorageMetadataAdapter()
            metadataAdapter.contentType = "image/jpeg"
            
            let downloadURL = try await storageService.uploadImage(imageData, path: imagePath, metadata: metadataAdapter)
            
            self.imageURL = downloadURL
            self.imageUploadState = .success
        } catch {
            imageUploadState = .failure
            throw error
        }
    }

    func resetForm() {
        eventTitle = "New event"
        eventDescription = "Tap here to enter your description"
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .idle
        eventCreationSuccess = false
        errorMessage = ""
        imageURL = ""
    }
}
