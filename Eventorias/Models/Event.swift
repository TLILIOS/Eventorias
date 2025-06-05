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
                id: "1",
                title: "Music festival",
                description: "Une soirée jazz avec les meilleurs musiciens locaux",
                date: Date().addingTimeInterval(60*60*24*3),
                location: "Paris",
                organizer: "Club de Jazz",
                organizerImageURL: "https://images.unsplash.com/photo-1494790108755-2616b612b786?w=150",
                imageURL: "https://images.unsplash.com/photo-1511192336575-5a79af67a629",
                category: "Musique",
                tags: ["Jazz", "Concert", "Musique Live"],
                createdAt: Date()
            ),
            Event(
                id: "2",
                title: "Art exhibition",
                description: "Découvrez les œuvres des artistes contemporains",
                date: Date().addingTimeInterval(60*60*24*7),
                location: "Lyon",
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
                location: "Bordeaux",
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
                location: "Marseille",
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
                location: "Toulouse",
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
                location: "Nice",
                organizer: "Cinéma Rex",
                organizerImageURL: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150",
                imageURL: "https://images.unsplash.com/photo-1489599843, 433-adea4ebd8685",
                category: "Cinéma",
                tags: ["Film", "Première", "Cinéma"],
                createdAt: Date()
            ),
            Event(
                id: "7",
                title: "Charity run",
                description: "Course caritative pour une bonne cause",
                date: Date().addingTimeInterval(60*60*24*42),
                location: "Strasbourg",
                organizer: "Association Sport & Solidarité",
                organizerImageURL: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150",
                imageURL: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b",
                category: "Sport",
                tags: ["Course", "Charité", "Sport"],
                createdAt: Date()
            )
        ]
    }
}
