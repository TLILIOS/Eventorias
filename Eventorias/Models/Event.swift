//
//  Event.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 02/06/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseFirestore

struct Event: Identifiable, Codable {
    @DocumentID var id: String?
    var title: String
    var description: String
    var date: Date
    var location: String
    var organizer: String
    var organizerImageURL: String?
    var imageURL: String?
    var category: String
    var tags: [String]?
    var createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case date
        case location
        case organizer
        case organizerImageURL = "organizer_image_url"
        case imageURL = "image_url"
        case category
        case tags
        case createdAt = "created_at"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}


// Extension pour faciliter la création de données de test
extension Event {
    static var sampleEvents: [Event] {
        [
            Event(
                id: "2",
                title: "Art exhibition",
                description: "Découvrez les œuvres des artistes contemporains",
                date: Date().addingTimeInterval(60*60*24*7),
                location: "12 Rue de la République, 69002 Lyon",
                organizer: "Galerie Moderne",
                organizerImageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                imageURL: "https://images.unsplash.com/photo-1594122230689-45899d9e6f69",
                category: "Art",
                tags: ["Exposition", "Art", "Culture"],
                createdAt: Date()
            ),
            Event(
                id: "3",
                title: "Tech conference",
                description: "Conférence sur les dernières innovations technologiques",
                date: Date().addingTimeInterval(60*60*24*14),
                location: "85 Cours de l'Intendance, 33000 Bordeaux",
                organizer: "TechForum",
                organizerImageURL: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150",
                imageURL: "https://images.unsplash.com/photo-1505373877841-8d25f7d46678",
                category: "Technologie",
                tags: ["Tech", "Innovation", "Conférence"],
                createdAt: Date()
            ),
            Event(
                id: "4",
                title: "Food fair",
                description: "Découvrez les saveurs du monde",
                date: Date().addingTimeInterval(60*60*24*21),
                location: "2 Rue Henri Barbusse, 13001 Marseille",
                organizer: "Food Lovers",
                organizerImageURL: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150",
                imageURL: "https://images.unsplash.com/photo-1555939594-58d7cb561ad1",
                category: "Gastronomie",
                tags: ["Food", "Cuisine", "Festival"],
                createdAt: Date()
            ),
            Event(
                id: "5",
                title: "Book signing",
                description: "Rencontrez votre auteur préféré",
                date: Date().addingTimeInterval(60*60*24*28),
                location: "17 Rue de Metz, 31000 Toulouse",
                organizer: "Librairie Central",
                organizerImageURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
                imageURL: "https://images.unsplash.com/photo-1481627834876-b7833e8f5570",
                category: "Littérature",
                tags: ["Livre", "Auteur", "Signature"],
                createdAt: Date()
            ),
            Event(
                id: "6",
                title: "Film screening",
                description: "Projection en avant-première",
                date: Date().addingTimeInterval(60*60*24*35),
                location: "6 Avenue Jean Médecin, 06000 Nice",
                organizer: "Cinéma Rex",
                organizerImageURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
                imageURL: "https://images.unsplash.com/photo-1489599843433-adea4ebd8685",
                category: "Cinéma",
                tags: ["Film", "Première", "Cinéma"],
                createdAt: Date()
            ),
            Event(
                id: "7",
                title: "Charity run",
                description: "Course caritative pour une bonne cause",
                date: Date().addingTimeInterval(60*60*24*42),
                location: "Place Kléber, 67000 Strasbourg",
                organizer: "Association Sport & Solidarité",
                organizerImageURL: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b",
                category: "Sport",
                tags: ["Course", "Charité", "Sport"],
                createdAt: Date()
            ),
            Event(
                id: "8",
                title: "Workshop photographie",
                description: "Apprenez les techniques de photographie urbaine avec des professionnels",
                date: Date().addingTimeInterval(60*60*24*49),
                location: "15 Rue Crébillon, 44000 Nantes",
                organizer: "Studio Photo Vision",
                organizerImageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                imageURL: "https://images.unsplash.com/photo-1502920917128-1aa500764cbd",
                category: "Photographie",
                tags: ["Photo", "Workshop", "Urbain"],
                createdAt: Date()
            ),
            Event(
                id: "9",
                title: "Festival de jazz",
                description: "Trois jours de concerts avec les meilleurs artistes de jazz européens",
                date: Date().addingTimeInterval(60*60*24*56),
                location: "Place de la Comédie, 34000 Montpellier",
                organizer: "Jazz & Co Productions",
                organizerImageURL: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150",
                imageURL: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f",
                category: "Musique",
                tags: ["Jazz", "Festival", "Concert"],
                createdAt: Date()
            ),
            Event(
                id: "10",
                title: "Salon du jardinage",
                description: "Découvrez les dernières tendances en jardinage écologique",
                date: Date().addingTimeInterval(60*60*24*63),
                location: "Grand Palais, Boulevard des Cités Unies, 59000 Lille",
                organizer: "Jardins & Nature",
                organizerImageURL: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150",
                imageURL: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b",
                category: "Nature",
                tags: ["Jardinage", "Écologie", "Plantes"],
                createdAt: Date()
            ),
            Event(
                id: "11",
                title: "Marché de Noël artisanal",
                description: "Marché traditionnel avec des créateurs locaux et des spécialités régionales",
                date: Date().addingTimeInterval(60*60*24*70),
                location: "Parvis de la Cathédrale, 51100 Reims",
                organizer: "Artisans de Champagne",
                organizerImageURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
                imageURL: "https://images.unsplash.com/photo-1512474932049-78ac69ede12c",
                category: "Artisanat",
                tags: ["Noël", "Artisanat", "Marché"],
                createdAt: Date()
            ),
            Event(
                id: "12",
                title: "Conférence bien-être",
                description: "Journée dédiée à la méditation, yoga et développement personnel",
                date: Date().addingTimeInterval(60*60*24*77),
                location: "1 Rue Jean Jaurès, 74000 Annecy",
                organizer: "Zen & Harmony Center",
                organizerImageURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
                imageURL: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4",
                category: "Bien-être",
                tags: ["Méditation", "Yoga", "Détente"],
                createdAt: Date()
            ),
            Event(
                id: "13",
                title: "Spectacle de théâtre",
                description: "Représentation exceptionnelle de la troupe nationale dans un classique revisité",
                date: Date().addingTimeInterval(60*60*24*84),
                location: "8 Rue du Roi René, 84000 Avignon",
                organizer: "Théâtre du Palais",
                organizerImageURL: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150",
                imageURL: "https://images.unsplash.com/photo-1507924538820-ede94a04019d",
                category: "Théâtre",
                tags: ["Théâtre", "Spectacle", "Culture"],
                createdAt: Date()
            ),
            Event(
                id: "14",
                title: "Nuit des étoiles",
                description: "Observation astronomique avec télescopes et conférences sur l'univers",
                date: Date().addingTimeInterval(60*60*24*91),
                location: "4 Avenue Vercingétorix, 63000 Clermont-Ferrand",
                organizer: "Observatoire d'Auvergne",
                organizerImageURL: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150",
                imageURL: "https://images.unsplash.com/photo-1446776653964-20c1d3a81b06",
                category: "Science",
                tags: ["Astronomie", "Étoiles", "Science"],
                createdAt: Date()
            ),
            Event(
                id: "15",
                title: "Cours de salsa",
                description: "Initiation à la danse salsa avec des professeurs internationaux",
                date: Date().addingTimeInterval(60*60*24*98),
                location: "77 La Croisette, 06400 Cannes",
                organizer: "Latino Dance Academy",
                organizerImageURL: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150",
                imageURL: "https://images.unsplash.com/photo-1504609813442-a8924e83f76e",
                category: "Danse",
                tags: ["Salsa", "Danse", "Latino"],
                createdAt: Date()
            ),
            Event(
                id: "16",
                title: "Pitch startup",
                description: "Concours de présentation pour jeunes entrepreneurs et investisseurs",
                date: Date().addingTimeInterval(60*60*24*105),
                location: "11 Rue du Pré Botté, 35000 Rennes",
                organizer: "Innovation Hub Bretagne",
                organizerImageURL: "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150",
                imageURL: "https://images.unsplash.com/photo-1559136555-9303baea8ebd",
                category: "Business",
                tags: ["Startup", "Entrepreneuriat", "Innovation"],
                createdAt: Date()
            ),
            Event(
                id: "17",
                title: "Visite château médiéval",
                description: "Découverte guidée du patrimoine historique avec reconstitution d'époque",
                date: Date().addingTimeInterval(60*60*24*112),
                location: "1 Rue Viollet le Duc, 11000 Carcassonne",
                organizer: "Office du Tourisme",
                organizerImageURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
                imageURL: "https://images.unsplash.com/photo-1520637836862-4d197d17c43a",
                category: "Histoire",
                tags: ["Château", "Médiéval", "Patrimoine"],
                createdAt: Date()
            )
        ]
    }
}
