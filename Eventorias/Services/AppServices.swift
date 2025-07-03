import Foundation
import Firebase
import CoreLocation

// MARK: - DocumentSnapshot Protocol

/// Protocol to abstract DocumentSnapshot for better testability
protocol DocumentSnapshotProtocol {
    /// Whether the document exists
    var exists: Bool { get }
    
    /// Decode the document data as a specific type
    /// - Parameter type: The type to decode the data as
    /// - Returns: The decoded object
    /// - Throws: Error if decoding fails
    func data<T: Decodable>(as type: T.Type) throws -> T
}

// MARK: - Placemark Protocol

/// Protocol to abstract CLPlacemark for better testability
protocol PlacemarkProtocol {
    /// The location of the placemark
    var location: CLLocation? { get }
    
    /// The coordinate of the placemark (computed from location)
    var coordinate: CLLocationCoordinate2D? { get }
}

// MARK: - Service Implementations

// MARK: - Geocoding Service Protocol

/// Protocol for geocoding operations
protocol GeocodingService {
    /// Geocode an address to get placemarks
    /// - Parameter address: String address to geocode
    /// - Returns: Array of placemarks, may be empty if nothing is found
    /// - Throws: Error if geocoding fails
    func geocodeAddress(_ address: String) async throws -> [PlacemarkProtocol]
    
    /// Cancel any ongoing geocoding operations
    func cancelGeocoding()
}

// MARK: - Network Service Protocol

/// Protocol for network operations related to maps
protocol MapNetworkService {
    /// Validate and check the status of a map image URL
    /// - Parameter url: URL to validate
    /// - Parameter completion: Completion handler called with result or error
    func validateMapImageURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void)
}

// MARK: - Configuration Service Protocol

/// Protocol for configuration values
protocol ConfigurationService {
    /// Get the Google Maps API key
    var googleMapsAPIKey: String { get }
}

// MARK: - Protocol Extensions

// Add a default implementation for the coordinate computed property
extension PlacemarkProtocol {
    var coordinate: CLLocationCoordinate2D? {
        return location?.coordinate
    }
}

// Make CLPlacemark conform to our protocol
extension CLPlacemark: PlacemarkProtocol {
    // Already has location property
    // coordinate is provided by protocol extension
}

// MARK: - Firebase Document Adapter

/// Wrapper class to adapt Firebase's DocumentSnapshot to DocumentSnapshotProtocol
class FirebaseDocumentSnapshotWrapper: DocumentSnapshotProtocol {
    private let snapshot: DocumentSnapshot
    
    init(snapshot: DocumentSnapshot) {
        self.snapshot = snapshot
    }
    
    var exists: Bool {
        return snapshot.exists
    }
    
    func data<T>(as type: T.Type) throws -> T where T : Decodable {
        return try snapshot.data(as: type)
    }
}

// MARK: - Default Implementations

/// Default implementation of FirestoreServiceProtocol using Firebase
class DefaultEventFirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()
    
    func createEvent(_ event: Event) async throws {
        // Unwrapping sécurisé avec valeur par défaut
        let eventRef = db.collection("events").document(event.id ?? UUID().uuidString)
        try await eventRef.setData(from: event)
    }
    
    func updateEvent(_ event: Event) async throws {
        // Unwrapping sécurisé avec valeur par défaut
        let eventRef = db.collection("events").document(event.id ?? UUID().uuidString)
        try await eventRef.setData(from: event)
    }
    
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol {
        let snapshot = try await db.collection("events").document(eventID).getDocument()
        // Use a FirebaseDocumentSnapshotWrapper to adapt Firebase's DocumentSnapshot to our protocol
        return FirebaseDocumentSnapshotWrapper(snapshot: snapshot)
    }
    
    func getSampleEvent(eventID: String) throws -> Event {
        guard let sampleEvent = Event.sampleEvents.first(where: { $0.id == eventID }) else {
            throw EventDetailsError.noData
        }
        return sampleEvent
    }
    
    // MARK: - Invitation Management
    
    func createInvitation(_ invitation: Invitation) async throws {
        let invitationRef = db.collection("invitations").document(invitation.id ?? UUID().uuidString)
        try await invitationRef.setData(from: invitation)
    }
    
    func updateInvitation(_ invitation: Invitation) async throws {
        guard let id = invitation.id else {
            throw NSError(
                domain: "FirebaseFirestoreService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Invitation ID is required"]
            )
        }
        
        let invitationRef = db.collection("invitations").document(id)
        try await invitationRef.setData(from: invitation, merge: true)
    }
    
    func deleteInvitation(_ invitationId: String) async throws {
        let invitationRef = db.collection("invitations").document(invitationId)
        try await invitationRef.delete()
    }
    
    func getEventInvitations(eventId: String) async throws -> [Invitation] {
        let query = db.collection("invitations")
            .whereField("eventId", isEqualTo: eventId)
        
        let querySnapshot = try await query.getDocuments()
        var invitations: [Invitation] = []
        
        for document in querySnapshot.documents {
            if let invitation = try? document.data(as: Invitation.self) {
                invitations.append(invitation)
            }
        }
        
        return invitations
    }
    
    func getUserInvitations(userId: String) async throws -> [Invitation] {
        let query = db.collection("invitations")
            .whereField("inviteeId", isEqualTo: userId)
        
        let querySnapshot = try await query.getDocuments()
        var invitations: [Invitation] = []
        
        for document in querySnapshot.documents {
            if let invitation = try? document.data(as: Invitation.self) {
                invitations.append(invitation)
            }
        }
        
        return invitations
    }
}

/// Default implementation of GeocodingService using CoreLocation
class DefaultGeocodingService: GeocodingService {
    private let geocoder = CLGeocoder()
    
    func geocodeAddress(_ address: String) async throws -> [PlacemarkProtocol] {
        do {
            // CLPlacemarks conform to PlacemarkProtocol via our extension
            let placemarks = try await geocoder.geocodeAddressString(address)
            return placemarks
        } catch {
            // Transformer les erreurs de CoreLocation en nos propres types d'erreur
            switch error {
            case CLError.network:
                throw MapError.networkError("Problème de connexion lors du géocodage")
            case CLError.geocodeFoundNoResult:
                return []
            default:
                throw MapError.geocodingFailed("Erreur lors du géocodage: \(error.localizedDescription)")
            }
        }
    }
    
    /// Cancels any ongoing geocoding operations
    func cancelGeocoding() {
        geocoder.cancelGeocode()
    }
}

/// Default implementation of MapNetworkService using URLSession
class DefaultMapNetworkService: MapNetworkService {
    private let session = URLSession.shared
    
    func validateMapImageURL(_ url: URL, completion: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.setValue("image/png,image/jpeg,image/*", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 8.0
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.setValue("Mozilla/5.0 Eventorias/1.0", forHTTPHeaderField: "User-Agent")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(MapError.networkError(error.localizedDescription)))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(MapError.unknown("Réponse invalide")))
                return
            }
            
            switch httpResponse.statusCode {
            case 200:
                guard let data = data, !data.isEmpty else {
                    completion(.failure(MapError.invalidImageData))
                    return
                }
                
                if UIImage(data: data) != nil {
                    completion(.success(()))
                } else {
                    completion(.failure(MapError.invalidImageData))
                }
                
            case 400:
                completion(.failure(MapError.serverError(400)))
            case 403:
                completion(.failure(MapError.apiAccessRestricted))
            case 404:
                completion(.failure(MapError.serverError(404)))
            case 429:
                completion(.failure(MapError.apiQuotaExceeded))
            case 500, 502, 503, 504:
                completion(.failure(MapError.serverError(httpResponse.statusCode)))
            default:
                completion(.failure(MapError.serverError(httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
}

/// Default implementation of ConfigurationService
class DefaultConfigurationService: ConfigurationService {
    var googleMapsAPIKey: String {
        return Secrets.googleMapsAPIKey
    }
}

// MARK: - Common Error Types

/// Types d'erreurs générales pour les événements
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
enum MapError: Error, LocalizedError, Equatable {
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
    
    // Implementation of Equatable protocol
    static func == (lhs: MapError, rhs: MapError) -> Bool {
        switch (lhs, rhs) {
        case (.networkError(let leftMessage), .networkError(let rightMessage)):
            return leftMessage == rightMessage
        case (.apiKeyInvalid, .apiKeyInvalid):
            return true
        case (.apiQuotaExceeded, .apiQuotaExceeded):
            return true
        case (.apiAccessRestricted, .apiAccessRestricted):
            return true
        case (.invalidImageData, .invalidImageData):
            return true
        case (.geocodingFailed(let leftMessage), .geocodingFailed(let rightMessage)):
            return leftMessage == rightMessage
        case (.serverError(let leftCode), .serverError(let rightCode)):
            return leftCode == rightCode
        case (.unknown(let leftMessage), .unknown(let rightMessage)):
            return leftMessage == rightMessage
        default:
            return false
        }
    }
}
