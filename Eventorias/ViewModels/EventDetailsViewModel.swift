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
    // MARK: - Published Properties
    
    /// État de chargement
    @Published var isLoading = false
    
    /// Événement actuellement affiché
    @Published private(set) var event: Event?
    
    /// Coordonnées géographiques de l'événement
    @Published var coordinates: CLLocationCoordinate2D?
    
    /// URL de la carte statique
    @Published var mapImageURL: URL?
    
    /// Message d'erreur
    @Published var errorMessage = ""
    
    /// Contrôle l'affichage de l'erreur
    @Published var showingError = false
    
    /// État de chargement de la carte
    @Published var isLoadingMap = false
    
    // MARK: - Private Properties
    
    /// Clé API Google Maps
    private let googleMapsAPIKey = "YOUR_GOOGLE_MAPS_API_KEY" // À remplacer par votre clé API
    
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
        
        do {
            let documentSnapshot = try await db.collection("events").document(eventID).getDocument()
            
            guard documentSnapshot.exists else {
                throw NSError(domain: "EventDetailsViewModel",
                              code: 404,
                              userInfo: [NSLocalizedDescriptionKey: "Événement introuvable"])
            }
            
            let fetchedEvent = try documentSnapshot.data(as: Event.self)
            event = fetchedEvent
            
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
        guard let event = event, !event.location.isEmpty else { return }
        
        isLoadingMap = true
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(event.location)
            
            if let placemark = placemarks.first, let location = placemark.location {
                DispatchQueue.main.async {
                    self.coordinates = location.coordinate
                    self.generateMapImageURL()
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Impossible de géocoder l'adresse: \(error.localizedDescription)"
                print("❌ EventDetailsViewModel: Erreur de géocodage - \(error.localizedDescription)")
            }
        }
        
        isLoadingMap = false
    }
    
    /// Génère l'URL pour afficher une carte statique Google Maps
    private func generateMapImageURL() {
        guard let coordinates = coordinates else { return }
        
        let latitude = coordinates.latitude
        let longitude = coordinates.longitude
        
        // Construction de l'URL de l'API Google Maps Static
        var urlComponents = URLComponents(string: "https://maps.googleapis.com/maps/api/staticmap")!
        urlComponents.queryItems = [
            URLQueryItem(name: "center", value: "\(latitude),\(longitude)"),
            URLQueryItem(name: "zoom", value: "15"),
            URLQueryItem(name: "size", value: "600x300"),
            URLQueryItem(name: "markers", value: "color:red|\(latitude),\(longitude)"),
            URLQueryItem(name: "key", value: googleMapsAPIKey)
        ]
        
        mapImageURL = urlComponents.url
    }
    
    /// Vérifie si l'API key est définie
    var isMapAPIKeyConfigured: Bool {
        return googleMapsAPIKey != "YOUR_GOOGLE_MAPS_API_KEY"
    }
    
    /// Formate la date de l'événement
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
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: event.date)
    }
    
    /// Génère un tag de couleur pour une catégorie
    func colorForCategory() -> Color {
        guard let event = event else { return .blue }
        
        switch event.category.lowercased() {
        case "concert", "musique":
            return .purple
        case "atelier":
            return .orange
        case "sport":
            return .green
        case "conférence":
            return .blue
        case "exposition":
            return .pink
        default:
            return .red
        }
    }
    
    /// Annule toutes les tâches en cours
    func cancelTasks() {
        geocoder.cancelGeocode()
    }
}
