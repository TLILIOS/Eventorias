// EventDetailsViewModel.swift
// Eventorias
//
// Created by TLiLi Hamdi on 05/06/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit

@MainActor
final class EventDetailsViewModel: ObservableObject {
    
    // MARK: - Dependencies
    
    private let firestoreService: FirestoreServiceProtocol
    private let geocodingService: GeocodingService
    private let mapNetworkService: MapNetworkService
    private let configurationService: ConfigurationService
    private let authenticationService: AuthenticationServiceProtocol
    
    /// Mode test pour contrôler le comportement pendant les tests
    private let isTestMode: Bool
    
    /// Contrôle si le géocodage automatique doit être effectué
    private let shouldAutoGeocode: Bool
    
    // MARK: - Published Properties
    
    /// État de chargement général
    @Published var isLoading = false
    
    /// État de chargement spécifique à la carte
    @Published var isLoadingMap = false
    
    /// Événement actuellement affiché
    @Published  var event: Event?
    
    /// Coordonnées géographiques de l'événement
    @Published var coordinates: CLLocationCoordinate2D?
    
    /// URL de la carte statique à afficher
    @Published var mapImageURL: URL?
    
    /// Message d'erreur
    @Published var errorMessage = ""
    
    /// Contrôle l'affichage de l'erreur
    @Published var showingError = false
    
    /// ViewModel pour la gestion des invitations
    @Published var invitationViewModel: InvitationViewModel?
    
    /// Indique si l'utilisateur courant est l'organisateur de l'événement
    @Published var isOrganizer = false
    
    // MARK: - Initialization
    
    /// Initialisation avec injection de dépendances
    /// - Parameters:
    ///   - firestoreService: Service pour accéder aux données Firestore
    ///   - geocodingService: Service pour géocoder les adresses
    ///   - mapNetworkService: Service pour gérer les requêtes réseau de carte
    ///   - configurationService: Service pour accéder aux configurations de l'application
    ///   - isTestMode: Indique si l'application est en mode test
    ///   - shouldAutoGeocode: Contrôle si le géocodage automatique doit être effectué
    init(firestoreService: FirestoreServiceProtocol,
         geocodingService: GeocodingService,
         mapNetworkService: MapNetworkService,
         configurationService: ConfigurationService,
         authenticationService: AuthenticationServiceProtocol,
         isTestMode: Bool = false,
         shouldAutoGeocode: Bool = true) {
        
        self.firestoreService = firestoreService
        self.geocodingService = geocodingService
        self.mapNetworkService = mapNetworkService
        self.configurationService = configurationService
        self.authenticationService = authenticationService
        self.isTestMode = isTestMode || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        self.shouldAutoGeocode = shouldAutoGeocode
        
        // Initialisation du ViewModel des invitations
        self.invitationViewModel = InvitationViewModel(firestoreService: firestoreService, authService: authenticationService)
    }
    
    // MARK: - Public Methods
    
    /// Charge les détails d'un événement par son ID
    /// - Parameter eventID: ID de l'événement à charger
    func loadEvent(eventID: String) async {
        isLoading = true
        errorMessage = ""
        showingError = false
        isOrganizer = false
        coordinates = nil
        mapImageURL = nil
        
        print("📱 EventDetailsViewModel: Chargement de l'événement avec ID \(eventID)")
        
        if eventID.isEmpty {
            errorMessage = "ID d'événement invalide"
            showingError = true
            isLoading = false
            return
        }
        
        do {
            let documentSnapshot = try await firestoreService.getEventDocument(eventID: eventID)
            
            if documentSnapshot.exists {
                print("📱 EventDetailsViewModel: Événement trouvé dans Firestore")
                let fetchedEvent = try documentSnapshot.data(as: Event.self)
                event = fetchedEvent
                
                // Vérifier si l'utilisateur est l'organisateur de l'événement
                checkIfUserIsOrganizer(fetchedEvent)
                
                // Charger les invitations pour cet événement
                if let invitationVM = invitationViewModel {
                    let _ = Task<Void, Never> {
                        // Appel explicite à la méthode avec le type exact du paramètre
                        await (invitationVM as AbstractInvitationViewModel).loadInvitations(for: eventID)
                    }
                }
                
                // Géocodage automatique seulement si activé (pas en mode test par défaut)
                if shouldAutoGeocode {
                    await geocodeEventLocation()
                }
                
            } else {
                print("📱 EventDetailsViewModel: Événement non trouvé dans Firestore, recherche dans les exemples")
                do {
                    let sampleEvent = try firestoreService.getSampleEvent(eventID: eventID)
                    print("📱 EventDetailsViewModel: Événement trouvé dans les données d'exemple")
                    event = sampleEvent
                    
                    // Géocodage automatique seulement si activé
                    if shouldAutoGeocode {
                        await geocodeEventLocation()
                    }
                } catch {
                    throw EventDetailsError.noData
                }
            }
        } catch {
            errorMessage = "Impossible de charger les détails de l'événement: \(error.localizedDescription)"
            showingError = true
            print("❌ EventDetailsViewModel: Erreur de chargement - \(error.localizedDescription)")
        }
        
        isLoading = false
    }
    
    /// Convertit l'adresse de l'événement en coordonnées GPS et génère l'URL de la carte
    func geocodeEventLocation() async {
        guard let event = event, !event.location.isEmpty else {
            print("❌ EventDetailsViewModel: Adresse vide ou événement non défini")
            isLoadingMap = false
            return
        }
        
        // Si les coordonnées existent déjà, générer directement l'URL
        if let existingCoordinates = coordinates {
            print("✅ EventDetailsViewModel: Utilisation des coordonnées existantes")
            generateMapImageURL()
            return
        }
        
        isLoadingMap = true
        print("🗭️ EventDetailsViewModel: Tentative de géocodage pour l'adresse: \(event.location)")
        
        do {
            let placemarks = try await geocodingService.geocodeAddress(event.location)
            if let placemark = placemarks.first, let location = placemark.location {
                let coordinate = location.coordinate
                print("✅ EventDetailsViewModel: Géocodage réussi - Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
                self.coordinates = coordinate
                generateMapImageURL()
            } else {
                print("⚠️ EventDetailsViewModel: Géocodage n'a pas retourné de résultat")
                self.errorMessage = "Impossible de localiser l'adresse sur la carte"
                self.showingError = true
            }
        } catch {
            self.errorMessage = "Impossible de géocoder l'adresse: \(error.localizedDescription)"
            print("❌ EventDetailsViewModel: Erreur de géocodage - \(error.localizedDescription)")
        }
        
        isLoadingMap = false
    }
    
    /// Génère l'URL pour afficher une carte statique Google Maps
    func generateMapImageURL() {
        guard let coordinates = coordinates else {
            print("❌ EventDetailsViewModel: Pas de coordonnées disponibles pour générer la carte")
            return
        }
        
        let apiKey = configurationService.googleMapsAPIKey
        if apiKey.isEmpty || apiKey == "To do" || apiKey == "YOUR_API_KEY" {
            print("❌ EventDetailsViewModel: Clé API Google Maps non configurée")
            return
        }
        
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        print("🗺️ EventDetailsViewModel: Génération de l'URL pour la carte statique à \(latitude), \(longitude)")
        
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/staticmap")
        guard urlComponents != nil else {
            print("❌ EventDetailsViewModel: Impossible de créer l'URL de base pour Google Maps")
            return
        }
        
        let formatLat = String(format: "%.6f", latitude)
        let formatLon = String(format: "%.6f", longitude)
        let coordString = "\(formatLat),\(formatLon)"
        let markersValue = "color:red|\(coordString)"
        
        urlComponents!.queryItems = [
            URLQueryItem(name: "center", value: coordString),
            URLQueryItem(name: "zoom", value: "14"),
            URLQueryItem(name: "size", value: "400x200"),
            URLQueryItem(name: "markers", value: markersValue),
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "format", value: "png"),
            URLQueryItem(name: "maptype", value: "roadmap")
        ]
        
        guard let url = urlComponents!.url else {
            print("❌ EventDetailsViewModel: Échec de construction de l'URL pour Google Maps")
            return
        }
        
        self.mapImageURL = url
        print("✅ EventDetailsViewModel: URL de carte générée: \(url)")
        
        // Ne pas valider l'image en mode test
        if !isTestMode {
            validateAndPreloadMapImage()
        }
    }
    
    /// Vérifie si l'API key est définie et valide
    var isMapAPIKeyConfigured: Bool {
        let apiKey = configurationService.googleMapsAPIKey
        if apiKey.isEmpty ||
            apiKey == "To do" ||
            apiKey == "YOUR_API_KEY" ||
            apiKey.count < 20 {
            print("❌ EventDetailsViewModel: La clé API Google Maps n'est pas configurée correctement")
            return false
        }
        
        return true
    }
    
    /// Optimise l'URL de la carte et vérifie sa validité
    /// Vérifie si l'utilisateur courant est l'organisateur de l'événement
    /// - Parameter event: L'événement à vérifier
    private func checkIfUserIsOrganizer(_ event: Event) {
        guard let currentUserId = authenticationService.currentUser?.uid else {
            isOrganizer = false
            return
        }
        
        isOrganizer = event.organizer == currentUserId
        print("📱 EventDetailsViewModel: Utilisateur est organisateur: \(isOrganizer)")
    }
    
    private func validateAndPreloadMapImage() {
        guard let url = mapImageURL else {
            print("❌ EventDetailsViewModel: Aucune URL de carte disponible")
            return
        }
        
        isLoadingMap = true
        print("🗺️ EventDetailsViewModel: Vérification de l'URL de la carte Google Maps")
        
        mapNetworkService.validateMapImageURL(url) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoadingMap = false
                switch result {
                case .success(_):
                    print("✅ EventDetailsViewModel: Image de carte validée avec succès")
                    self?.errorMessage = ""
                    self?.showingError = false
                case .failure(let error):
                    if let mapError = error as? MapError {
                        print("❌ EventDetailsViewModel: Erreur de validation de carte - \(mapError.localizedDescription ?? "Erreur inconnue")")
                        self?.handleMapError(mapError)
                    } else {
                        print("❌ EventDetailsViewModel: Erreur inattendue - \(error.localizedDescription)")
                        self?.handleMapError(MapError.unknown(error.localizedDescription))
                    }
                    
                    if let mapError = error as? MapError, case .invalidImageData = mapError {
                        self?.mapImageURL = nil
                    }
                }
            }
        }
    }
    
    /// Gère les erreurs de carte et met à jour l'interface
    private func handleMapError(_ error: MapError) {
        errorMessage = error.errorDescription ?? "Erreur inconnue"
        showingError = true
        print("🛑 EventDetailsViewModel: Erreur de carte - \(errorMessage)")
        
        if case .invalidImageData = error {
            mapImageURL = nil
        }
    }
    
    // MARK: - Formatting Methods
    
    func formattedEventTime() -> String {
        guard let event = event else { return "" }
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: event.date)
    }
    
    func formattedEventDay() -> String {
        guard let event = event else { return "" }
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        return dayFormatter.string(from: event.date)
    }
    
    func formattedEventMonth() -> String {
        guard let event = event else { return "" }
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        return monthFormatter.string(from: event.date)
    }
    
    func formattedEventDate() -> String {
        guard let event = event else { return "" }
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: event.date)
    }
    
    func cancelTasks() {
        geocodingService.cancelGeocoding()
    }
}
