//
//  MockFirestoreService.swift
//  EventoriasTests
//
//  Created on 27/06/2025
//
import Foundation
import FirebaseFirestore
@testable import Eventorias

// Définition locale de FirestoreError pour les tests
enum FirestoreError: Error {
    case documentDoesNotExist
    case decodingError
    case encodingError
    case unknownError
}

class MockDocumentSnapshot: DocumentSnapshotProtocol {
    private let mockData: [String: Any]
    private let mockExists: Bool
    private let mockId: String
    
    init(exists: Bool, data: [String: Any], id: String = "mock-document-id") {
        self.mockExists = exists
        self.mockData = data
        self.mockId = id
    }
    
    var exists: Bool {
        return mockExists
    }
    
    // Ces propriétés ne font pas partie du protocole DocumentSnapshotProtocol
    // mais sont utilisées en interne par les tests
    var documentID: String {
        return mockId
    }
    
    func data() -> [String : Any]? {
        return mockExists ? mockData : nil
    }
    
    func data<T>(as type: T.Type) throws -> T where T : Decodable {
        print("\n📊 DÉBUT DÉCODAGE MockDocumentSnapshot.data(as:) 📊")
        print("📊 exists: \(exists)")
        
        if !exists {
            print("❌ ÉCHEC: Le document n'existe pas")
            throw FirestoreError.documentDoesNotExist
        }
        
        print("📊 Type demandé: \(type)")
        print("📊 Document ID: \(documentID)")
        print("📊 Contenu mockData: \(mockData)")
        
        // Vérification que mockData contient un ID
        if let idValue = mockData["id"] {
            print("📊 ID trouvé dans les données: \(idValue)")
        } else {
            print("⚠️ ATTENTION: Aucun ID trouvé dans les données! Ajout automatique de l'ID")
            var mutableData = mockData
            mutableData["id"] = documentID
        }
        
        do {
            // Pour contourner le problème du décodage @DocumentID, deux approches sont possibles :
            // 1. Soit créer une copie du modèle Event sans @DocumentID (approche complexe)
            // 2. Soit adapter notre approche pour éviter d'utiliser Firestore.Decoder (approche choisie ici)
            
            // Au lieu d'utiliser Firestore.Decoder, on va construire directement l'objet 
            // en créant un dictionnaire avec toutes les données SAUF le champ id
            // puis en attribuant manuellement l'ID
            if type == Event.self {
                print("📊 Détecté décodage d'un Event, approche spéciale pour @DocumentID")
                
                // Création manuelle d'un Event à partir des données du dictionnaire
                // sans passer par le décodeur JSON qui pose problème avec @DocumentID
                do {
                    // Vérification des champs obligatoires
                    guard let title = mockData["title"] as? String,
                          let description = mockData["description"] as? String,
                          let location = mockData["location"] as? String,
                          let organizer = mockData["organizer"] as? String,
                          let categoryString = mockData["category"] as? String else {
                        print("❌ Champs obligatoires manquants dans les données mock")
                        throw FirestoreError.decodingError
                    }
                    
                    // Conversion des timestamps en dates
                    let dateTimestamp = mockData["date"] as? TimeInterval ?? Date().timeIntervalSince1970
                    let createdAtTimestamp = mockData["createdAt"] as? TimeInterval ?? Date().timeIntervalSince1970
                    
                    let date = Date(timeIntervalSince1970: dateTimestamp)
                    let createdAt = Date(timeIntervalSince1970: createdAtTimestamp)
                    
                    // Champs optionnels
                    let imageURL = mockData["imageURL"] as? String
                    let organizerImageURL = mockData["organizerImageURL"] as? String
                    let tags = mockData["tags"] as? [String]
                    
                    // Création de l'Event
                    var event = Event(
                        title: title,
                        description: description,
                        date: date,
                        location: location,
                        organizer: organizer,
                        organizerImageURL: organizerImageURL,
                        imageURL: imageURL,
                        category: EventCategory.fromString(categoryString),
                        tags: tags,
                        createdAt: createdAt
                    )
                    
                    // Attribution explicite de l'ID
                    event.id = documentID
                    print("✅ Event créé manuellement avec succès - ID: \(documentID)")
                    
                    return event as! T
                } catch {
                    print("❌ Erreur lors de la création manuelle de l'Event: \(error)")
                    throw FirestoreError.decodingError
                }
            }
            
            // Pour les autres types que Event, on utilise la méthode standard
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            // Pour le débogage, afficher les données
            if let jsonData = try? JSONSerialization.data(withJSONObject: mockData, options: .prettyPrinted),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("📊 JSON formaté: \(jsonString)")
            }
            
            // Conversion du dictionnaire en Data pour le décodage
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: mockData)
                let decodedObject = try decoder.decode(type, from: jsonData)
                print("✅ Décodage réussi pour \(type)")
                return decodedObject
            } catch let decodingError as DecodingError {
                debugDecodingError(decodingError)
                throw decodingError
            } catch {
                print("❌ Autre erreur de décodage: \(error)")
                throw error
            }
        } catch {
            print("❌ Erreur de sérialisation JSON: \(error)")
            throw FirestoreError.encodingError
        }
    }
    
    // Méthode helper pour déboguer les erreurs de décodage
    private func debugDecodingError(_ error: DecodingError) {
        print("\n❌ ERREUR DE DÉCODAGE DÉTAILLÉE:")
        switch error {
        case .dataCorrupted(let context):
            print("Données corrompues: \(context.debugDescription)")
            print("Chemin: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
        case .keyNotFound(let key, let context):
            print("Clé introuvable: \(key.stringValue)")
            print("Chemin: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            if let debugDescription = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Description: \(debugDescription)")
            }
        case .typeMismatch(let type, let context):
            print("Type incorrect: attendu \(type)")
            print("Chemin: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            if let debugDescription = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Description: \(debugDescription)")
            }
        case .valueNotFound(let type, let context):
            print("Valeur introuvable pour le type \(type)")
            print("Chemin: \(context.codingPath.map { $0.stringValue }.joined(separator: "."))")
            if let debugDescription = context.debugDescription.isEmpty ? nil : context.debugDescription {
                print("Description: \(debugDescription)")
            }
        @unknown default:
            print("Erreur de décodage inconnue")
        }
    }
}

class MockFirestoreService: FirestoreServiceProtocol {
    // Variables pour suivre les appels de méthodes
    var createEventCalled = false
    var updateEventCalled = false
    var getEventDocumentCalled = false
    var getSampleEventCalled = false
    var deleteEventCalled = false
    var getEventsForUserCalled = false
    var getAllEventsCalled = false
    // var getEventsWithFilterCalled = false
    
    // Variables pour contrôler le comportement simulé
    var shouldThrowError = false
    var mockError: Error = NSError(domain: "MockFirestoreError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Erreur simulée"])
    
    // Mockées pour les tests
    var mockDocument: DocumentSnapshotProtocol?
    var mockEvents: [Event] = []
    var mockQuerySnapshot: [DocumentSnapshotProtocol] = []
    
    // Mock pour les invitations
    var mockGetEventInvitations: MockMethod<String, [Invitation]>?
    
    func createEvent(_ event: Event) async throws {
        createEventCalled = true
        if shouldThrowError {
            throw mockError
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        updateEventCalled = true
        if shouldThrowError {
            throw mockError
        }
    }
    
    func getEventDocument(eventID: String) async throws -> DocumentSnapshotProtocol {
        getEventDocumentCalled = true
        if shouldThrowError {
            throw mockError
        }
        return mockDocument ?? MockDocumentSnapshot(exists: false, data: [:])
    }
    
    func getSampleEvent(eventID: String) throws -> Event {
        getSampleEventCalled = true
        if shouldThrowError {
            throw mockError
        }
        
        // D'abord chercher dans les événements mockés pour les tests
        if let event = mockEvents.first(where: { $0.id == eventID }) {
            return event
        }
        
        // Ensuite chercher dans les événements d'exemple
        if let sampleEvent = Event.sampleEvents.first(where: { $0.id == eventID }) {
            return sampleEvent
        }
        
        // En dernier recours, retourner un événement par défaut
        return Event(
            id: eventID,
            title: "Événement exemple",
            description: "Description de l'événement exemple",
            date: Date(),
            location: "123 Rue Exemple, Paris",
            organizer: "Organisateur Exemple",
            organizerImageURL: "https://example.com/organizer.jpg",
            imageURL: "https://example.com/image.jpg",
            category: .other,
            tags: ["exemples", "test"],
            createdAt: Date()
        )
    }
    func resetFlags() {
        createEventCalled = false
        updateEventCalled = false
        getEventDocumentCalled = false
        getSampleEventCalled = false
        deleteEventCalled = false
        getEventsForUserCalled = false
        getAllEventsCalled = false
        // getEventsWithFilterCalled = false
        createInvitationCalled = false
        updateInvitationCalled = false
        deleteInvitationCalled = false
        getEventInvitationsCalled = false
        getUserInvitationsCalled = false
        shouldThrowError = false
    }
    
    // MARK: Implémentation des méthodes de gestion des invitations
    
//    func createInvitation(_ invitation: Invitation) async throws {
//        createInvitationCalled = true
//        if shouldThrowError {
//            throw mockError
//        }
//    }
//    
//    func updateInvitation(_ invitation: Invitation) async throws {
//        updateInvitationCalled = true
//        if shouldThrowError {
//            throw mockError
//        }
//    }
//    
//    func deleteInvitation(_ invitationId: String) async throws {
//        deleteInvitationCalled = true
//        if shouldThrowError {
//            throw mockError
//        }
//    }
//    
//    func getEventInvitations(eventId: String) async throws -> [Invitation] {
//        getEventInvitationsCalled = true
//        if shouldThrowError {
//            throw mockError
//        }
//        return mockInvitations.filter { $0.eventId == eventId }
//    }

    
    func deleteEvent(eventID: String) async throws {
        deleteEventCalled = true
        if shouldThrowError {
            throw mockError
        }
    }
    
    func getEventsForUser(userID: String) async throws -> [Event] {
        getEventsForUserCalled = true
        if shouldThrowError {
            throw mockError
        }
        return mockEvents
    }
    
    func getAllEvents() async throws -> [Event] {
        getAllEventsCalled = true
        if shouldThrowError {
            throw mockError
        }
        return mockEvents
    }
    
    // MARK: - Variables de suivi pour les invitations
    
    var createInvitationCalled = false
    var updateInvitationCalled = false
    var deleteInvitationCalled = false
    var getEventInvitationsCalled = false
    var getUserInvitationsCalled = false
    var mockInvitations: [Invitation] = []
    
    func getUserInvitations(userId: String) async throws -> [Invitation] {
        getUserInvitationsCalled = true
        if shouldThrowError {
            throw mockError
        }
        return mockInvitations.filter { $0.inviteeId == userId }
    }
    
    
}
