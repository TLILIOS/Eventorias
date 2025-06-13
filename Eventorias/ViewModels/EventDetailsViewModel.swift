//
//  EventDetailsViewModel.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit
import Firebase

@MainActor
final class EventDetailsViewModel: ObservableObject {
    // MARK: - Enums
    
    /// Types d'erreurs générales
    enum EventDetailsError: Error, LocalizedError {
        case networkError
        case decodingError
        case noData
        case serverError
        case geocodingError
        
        var errorDescription: String? {
            switch self {
            case .networkError:
                return "Erreur de connexion réseau"
            case .decodingError:
                return "Erreur de décodage des données"
            case .noData:
                return "Aucune donnée disponible"
            case .serverError:
                return "Erreur serveur"
            case .geocodingError:
                return "Impossible de géocoder l'adresse"
            }
        }
    }
    
    /// Types d'erreurs possibles pour la carte
    enum MapError: Error, LocalizedError {
        case networkError(String)
        case apiKeyInvalid
        case apiQuotaExceeded
        case apiAccessRestricted
        case invalidImageData
        case geocodingFailed(String)
        case serverError(Int)
        case unknown(String)
        
        var errorDescription: String? {
            switch self {
            case .networkError(let message):
                return "Impossible de se connecter au serveur: \(message)"
            case .apiKeyInvalid:
                return "Clé API Google Maps invalide"
            case .apiQuotaExceeded:
                return "Quota Google Maps dépassé"
            case .apiAccessRestricted:
                return "Accès à l'API Google Maps restreint"
            case .invalidImageData:
                return "Données d'image invalides"
            case .geocodingFailed(let message):
                return "Échec du géocodage: \(message)"
            case .serverError(let code):
                return "Erreur serveur (\(code))"
            case .unknown(let message):
                return "Erreur inconnue: \(message)"
            }
        }
    }
    /// État de chargement général
    @Published var isLoading = false
    
    /// État de chargement spécifique à la carte
    @Published var isLoadingMap = false
    
    /// Événement actuellement affiché
    @Published private(set) var event: Event?
    
    /// Coordonnées géographiques de l'événement
    @Published var coordinates: CLLocationCoordinate2D?
    
    /// URL de la carte statique à afficher
    @Published var mapImageURL: URL?
    
    /// Message d'erreur
    @Published var errorMessage = ""
    
    /// Contrôle l'affichage de l'erreur
    @Published var showingError = false
    
    /// Clé API Google Maps
    private let googleMapsAPIKey = "AIzaSyDB5MkjrYJCdIYS_rCT2QiBs6jocJ7sY-g"
    
    /// Référence Firestore
    private let db = Firestore.firestore()
    
    /// Géocodeur pour convertir adresses en coordonnées
    private let geocoder = CLGeocoder()
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    /// Charge les détails d'un événement par son ID
    /// - Parameter eventID: ID de l'événement à charger
    func loadEvent(eventID: String) async {
        isLoading = true
        errorMessage = ""
        showingError = false
        
        print("📱 EventDetailsViewModel: Chargement de l'événement avec ID \(eventID)")
        
        // Vérifier si l'ID est vide
        if eventID.isEmpty {
            errorMessage = "ID d'événement invalide"
            showingError = true
            isLoading = false
            print("❌ EventDetailsViewModel: ID d'événement vide")
            return
        }
        
        do {
            // Essayer de récupérer l'événement depuis Firestore
            let documentSnapshot = try await db.collection("events").document(eventID).getDocument()
            
            // Si l'événement existe dans Firestore
            if documentSnapshot.exists {
                print("📱 EventDetailsViewModel: Événement trouvé dans Firestore")
                let fetchedEvent = try documentSnapshot.data(as: Event.self)
                event = fetchedEvent
            } else {
                // Si non trouvé dans Firestore, chercher dans les données d'exemple
                print("📱 EventDetailsViewModel: Événement non trouvé dans Firestore, recherche dans les exemples")
                if let sampleEvent = Event.sampleEvents.first(where: { $0.id == eventID }) {
                    print("📱 EventDetailsViewModel: Événement trouvé dans les données d'exemple")
                    event = sampleEvent
                } else {
                    throw EventDetailsError.noData
                }
            }
            
            // Géocoder l'adresse
            await geocodeEventLocation()
            
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
        
        isLoadingMap = true
        print("🗺️ EventDetailsViewModel: Tentative de géocodage pour l'adresse: \(event.location)")
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(event.location)
            
            if let placemark = placemarks.first, let location = placemark.location {
                let coordinate = location.coordinate
                print("✅ EventDetailsViewModel: Géocodage réussi - Lat: \(coordinate.latitude), Lon: \(coordinate.longitude)")
                
                self.coordinates = coordinate
                self.generateMapImageURL()
            } else {
                print("⚠️ EventDetailsViewModel: Géocodage n'a pas retourné de résultat")
                self.errorMessage = "Impossible de localiser l'adresse sur la carte"
            }
        } catch {
            self.errorMessage = "Impossible de géocoder l'adresse: \(error.localizedDescription)"
            print("❌ EventDetailsViewModel: Erreur de géocodage - \(error.localizedDescription)")
        }
        
        isLoadingMap = false
    }
    
    /// Génère l'URL pour afficher une carte statique Google Maps
    private func generateMapImageURL() {
        guard let coordinates = coordinates else { 
            print("❌ EventDetailsViewModel: Pas de coordonnées disponibles pour générer la carte")
            return 
        }
        
        // Vérifier que la clé API n'est pas vide ou la valeur par défaut
        if googleMapsAPIKey.isEmpty || googleMapsAPIKey == "To do" || googleMapsAPIKey == "YOUR_API_KEY" {
            print("❌ EventDetailsViewModel: Clé API Google Maps non configurée")
            return
        }
        
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        
        print("🗺️ EventDetailsViewModel: Génération de l'URL pour la carte statique à \(latitude), \(longitude)")
        
        // Construction de l'URL de l'API Google Maps Static
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/staticmap")
        
        guard urlComponents != nil else {
            print("❌ EventDetailsViewModel: Impossible de créer l'URL de base pour Google Maps")
            return
        }
        
        // Formatter les coordonnées avec un nombre limité de décimales pour éviter les problèmes d'encodage
        let formatLat = String(format: "%.6f", latitude) 
        let formatLon = String(format: "%.6f", longitude)
        
        // Construire manuellement le paramètre markers pour éviter les problèmes d'encodage du pipe
        let coordString = "\(formatLat),\(formatLon)"
        let markersValue = "color:red|\(coordString)"
        
        // Paramètres de l'API avec valeurs simplifiées
        urlComponents!.queryItems = [
            URLQueryItem(name: "center", value: coordString),
            URLQueryItem(name: "zoom", value: "14"),
            URLQueryItem(name: "size", value: "400x200"),
            URLQueryItem(name: "markers", value: markersValue),
            URLQueryItem(name: "key", value: googleMapsAPIKey),
            URLQueryItem(name: "format", value: "png"),
            URLQueryItem(name: "maptype", value: "roadmap")
        ]
        
        // Vérifier si l'URL générée est correctement construite
        if let urlString = urlComponents!.url?.absoluteString {
            print("🗺️ URL inspect: \(urlString)")
            
            // Vérifier si le caractère | est correctement encodé
            if !urlString.contains("|") && urlString.contains("%7C") {
                print("✅ Caractère pipe correctement encodé")
            } else if urlString.contains("|") {
                print("⚠️ Attention: Le caractère pipe n'est pas encodé")
                
                // Encoder manuellement le caractère pipe si nécessaire
                let correctUrlString = urlString.replacingOccurrences(of: "|", with: "%7C")
                if let correctUrl = URL(string: correctUrlString) {
                    print("✅ URL corrigée manuellement")
                    self.mapImageURL = correctUrl
                    return
                }
            }
        }
        
        guard let url = urlComponents!.url else {
            print("❌ EventDetailsViewModel: Échec de construction de l'URL pour Google Maps")
            return
        }
        
        // Définir directement l'URL sans test pour éviter les erreurs
        self.mapImageURL = url
        print("✅ EventDetailsViewModel: URL de carte générée: \(url)")
        
        // Valider et précharger l'image de la carte
        validateAndPreloadMapImage()
    }
    
    /// Vérifie si l'API key est définie et valide
    var isMapAPIKeyConfigured: Bool {
        if googleMapsAPIKey.isEmpty || 
           googleMapsAPIKey == "To do" || 
           googleMapsAPIKey == "YOUR_API_KEY" ||
           googleMapsAPIKey.count < 20 {
            print("❌ EventDetailsViewModel: La clé API Google Maps n'est pas configurée correctement")
            return false
        }
        return true
    }
    
    /// Optimise l'URL de la carte et vérifie sa validité
    private func validateAndPreloadMapImage() {
        guard let url = mapImageURL else { 
            print("❌ EventDetailsViewModel: Aucune URL de carte disponible")
            return 
        }
        
        isLoadingMap = true
        
        // Configuration optimisée de la requête pour Google Maps
        var request = URLRequest(url: url)
        request.setValue("image/png,image/jpeg,image/*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8.0 // Temps raisonnable pour charger la carte
        request.cachePolicy = .reloadIgnoringLocalCacheData // Contourner tout problème de cache
        
        // Ajouter un User-Agent pour éviter des blocages API potentiels
        request.setValue("Mozilla/5.0 Eventorias/1.0", forHTTPHeaderField: "User-Agent")
        
        print("🗺️ EventDetailsViewModel: Vérification de l'URL de la carte Google Maps")
        
        // Exécuter la requête pour vérifier si l'URL est valide
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoadingMap = false
                
                // Gestion des erreurs réseau
                if let error = error {
                    print("❌ EventDetailsViewModel: Erreur réseau - \(error.localizedDescription)")
                    let networkError = MapError.networkError(error.localizedDescription)
                    self?.handleMapError(networkError)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("❌ EventDetailsViewModel: Réponse HTTP invalide")
                    self?.handleMapError(MapError.unknown("Réponse invalide"))
                    return
                }
                
                // Analyse du code de statut HTTP
                switch httpResponse.statusCode {
                case 200:
                    guard let data = data, !data.isEmpty else {
                        print("❌ EventDetailsViewModel: Données d'image vides")
                        self?.handleMapError(MapError.invalidImageData)
                        return
                    }
                    // Vérifier que les données sont bien une image
                    if UIImage(data: data) != nil {
                        print("✅ EventDetailsViewModel: Image de carte validée avec succès")
                        self?.errorMessage = ""
                        self?.showingError = false
                    } else {
                        print("❌ EventDetailsViewModel: Les données reçues ne sont pas une image valide")
                        self?.handleMapError(MapError.invalidImageData)
                    }
                    
                case 400:
                    // Erreur de requête - URL mal formée
                    print("❌ EventDetailsViewModel: URL de carte mal formée (400)")
                    self?.handleMapError(MapError.serverError(400))
                    
                case 403:
                    // Accès refusé - problème de clé API
                    print("❌ EventDetailsViewModel: Accès refusé à l'API Google Maps (403)")
                    self?.handleMapError(MapError.apiAccessRestricted)
                    
                case 404:
                    // Ressource non trouvée
                    print("❌ EventDetailsViewModel: Ressource carte non trouvée (404)")
                    self?.handleMapError(MapError.serverError(404))
                    
                case 429:
                    // Quota dépassé
                    print("❌ EventDetailsViewModel: Quota API Google Maps dépassé (429)")
                    self?.handleMapError(MapError.apiQuotaExceeded)
                    
                case 500, 502, 503, 504:
                    // Erreur serveur
                    print("❌ EventDetailsViewModel: Erreur serveur Google Maps (\(httpResponse.statusCode))")
                    self?.handleMapError(MapError.serverError(httpResponse.statusCode))
                    
                default:
                    // Autre erreur
                    print("❌ EventDetailsViewModel: Erreur HTTP inattendue (\(httpResponse.statusCode))")
                    self?.handleMapError(MapError.serverError(httpResponse.statusCode))
                }
            }
        }
        
        task.resume()
    }
    
    /// Gère les erreurs de carte et met à jour l'interface
    private func handleMapError(_ error: MapError) {
        // Afficher le message d'erreur
        errorMessage = error.errorDescription ?? "Erreur inconnue"
        showingError = true
        
        // Enregistrer l'erreur dans les logs pour analyse
        print("🛑 EventDetailsViewModel: Erreur de carte - \(errorMessage)")
        
        // Réinitialiser l'URL pour empêcher AsyncImage d'essayer de charger une image invalide
        if case .invalidImageData = error {
            mapImageURL = nil
        }
    }
    
    func formattedEventTime() -> String {
        guard let event = event else { return "" }
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        return timeFormatter.string(from: event.date)
    }
    
    /// Formate le jour de l'événement
    func formattedEventDay() -> String {
        guard let event = event else { return "" }
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "d"
        return dayFormatter.string(from: event.date)
    }
    
    /// Formate le mois de l'événement
    func formattedEventMonth() -> String {
        guard let event = event else { return "" }
        
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "MMM"
        return monthFormatter.string(from: event.date)
    }
    
    /// Formate la date complète de l'événement
    func formattedEventDate() -> String {
        guard let event = event else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "en_US")
        return formatter.string(from: event.date)
    }

    
    /// Annule toutes les tâches en cours
    func cancelTasks() {
        geocoder.cancelGeocode()
    }
}
