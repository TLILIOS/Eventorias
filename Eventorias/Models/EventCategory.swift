//
//  EventCategory.swift
//  Eventorias
//
//  Created on 03/07/2025
//

import Foundation
import SwiftUI

enum EventCategory: String, CaseIterable, Identifiable, Codable {
    case music = "Musique"
    case sport = "Sport"
    case art = "Art & Culture"
    case technology = "Technologie"
    case business = "Affaires"
    case food = "Gastronomie"
    case social = "Social"
    case education = "Éducation"
    case entertainment = "Divertissement"
    case other = "Autre"
    
    var id: String { self.rawValue }
    
    // Icône associée à chaque catégorie
    var icon: String {
        switch self {
        case .music:
            return "music.note"
        case .sport:
            return "figure.run"
        case .art:
            return "paintbrush"
        case .technology:
            return "desktopcomputer"
        case .business:
            return "briefcase"
        case .food:
            return "fork.knife"
        case .social:
            return "person.3"
        case .education:
            return "book"
        case .entertainment:
            return "film"
        case .other:
            return "ellipsis.circle"
        }
    }
    
    // Couleur associée à chaque catégorie
    var color: Color {
        switch self {
        case .music:
            return .purple
        case .sport:
            return .blue
        case .art:
            return .pink
        case .technology:
            return .gray
        case .business:
            return .green
        case .food:
            return .orange
        case .social:
            return .yellow
        case .education:
            return .cyan
        case .entertainment:
            return .red
        case .other:
            return .gray
        }
    }
    
    // Convertir une String en EventCategory
    static func fromString(_ string: String) -> EventCategory {
        return EventCategory.allCases.first(where: { $0.rawValue == string }) ?? .other
    }
}
