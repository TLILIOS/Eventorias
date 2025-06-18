//
//  EventTestFactory.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation
@testable import Eventorias

/// Factory class for creating test data for event-related tests
class EventTestFactory {
    /// Creates a single event with configurable properties
    /// - Parameters:
    ///   - id: The event ID (default: "test-event-1")
    ///   - title: The event title (default: "Test Event")
    ///   - description: The event description (default: "This is a test event")
    ///   - date: The event date (default: current date)
    ///   - location: The event location (default: "Test Location")
    ///   - category: The event category (default: "Test")
    ///   - imageURL: The event image URL (default: nil)
    /// - Returns: A configured Event instance
    static func createEvent(
        id: String = "test-event-1",
        title: String = "Test Event",
        description: String = "This is a test event",
        date: Date = Date(),
        location: String = "Test Location",
        organizer: String = "Test Organizer",
        organizerImageURL: String? = nil,
        imageURL: String? = nil,
        category: String = "Test",
        tags: [String]? = ["Test"],
        createdAt: Date = Date()
    ) -> Event {
        return Event(
            id: id,
            title: title,
            description: description,
            date: date,
            location: location,
            organizer: organizer,
            organizerImageURL: organizerImageURL,
            imageURL: imageURL,
            category: category,
            tags: tags,
            createdAt: createdAt
        )
    }
    
    /// Creates a list of events with sequential IDs
    /// - Parameter count: Number of events to create (default: 3)
    /// - Returns: Array of Event objects
    static func createEventsList(count: Int = 3) -> [Event] {
        return (1...count).map { index in
            createEvent(
                id: "test-event-\(index)",
                title: "Test Event \(index)",
                description: "This is test event number \(index)",
                date: Calendar.current.date(byAdding: .day, value: index, to: Date()) ?? Date(),
                location: "Test Location \(index)",
                organizer: "Organizer \(index)",
                organizerImageURL: index % 3 == 0 ? "https://example.com/organizer\(index).jpg" : nil,
                imageURL: index % 2 == 0 ? "https://example.com/event\(index).jpg" : nil,
                category: index % 2 == 0 ? "Workshop" : "Conference",
                tags: ["Tag\(index)", index % 2 == 0 ? "Workshop" : "Conference"],
                createdAt: Calendar.current.date(byAdding: .hour, value: -index, to: Date()) ?? Date()
            )
        }
    }
    
    /// Creates a mock error for testing error paths
    /// - Parameter description: Custom error description (default: "Test error")
    /// - Returns: Error object
    static func createError(description: String = "Test error") -> NSError {
        return NSError(
            domain: "EventoriasTests",
            code: 1001,
            userInfo: [NSLocalizedDescriptionKey: description]
        )
    }
}
