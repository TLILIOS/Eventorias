//
//  EventServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation
import CoreLocation
import UIKit

/// Protocol defining the contract for event-related services
protocol EventServiceProtocol {
    /// Fetches all events from the data source
    /// - Returns: Array of Event objects
    /// - Throws: Error if fetching fails
    func fetchEvents() async throws -> [Event]
    
    /// Searches for events based on a query string
    /// - Parameter query: The search query
    /// - Returns: Array of matching Event objects
    /// - Throws: Error if search fails
    func searchEvents(query: String) async throws -> [Event]
    
    /// Filters events by category
    /// - Parameter category: The category to filter by
    /// - Returns: Array of matching Event objects
    /// - Throws: Error if filtering fails
    func filterEventsByCategory(category: String) async throws -> [Event]
    
    /// Gets events sorted by date
    /// - Parameter ascending: If true, sorts from oldest to newest; if false, newest to oldest
    /// - Returns: Array of sorted Event objects
    /// - Throws: Error if sorting fails
    func getEventsSortedByDate(ascending: Bool) async throws -> [Event]
    
    /// Adds sample events to the data source
    /// - Throws: Error if adding fails
    func addSampleEvents() async throws
    
    /// Checks if the events collection is empty
    /// - Returns: Boolean indicating if collection is empty
    /// - Throws: Error if check fails
    func isEventsCollectionEmpty() async throws -> Bool
    
    /// Creates a new event
    /// - Parameters:
    ///   - title: The event title
    ///   - description: The event description
    ///   - date: The event date
    ///   - location: The event location
    ///   - imageURL: Optional URL to the event image
    /// - Returns: ID of the created event
    /// - Throws: Error if creation fails
    func createEvent(title: String, description: String, date: Date, location: String, imageURL: String?) async throws -> String
    
    /// Uploads an image to storage
    /// - Parameter imageData: The image data to upload
    /// - Returns: URL to the uploaded image
    /// - Throws: Error if upload fails
    func uploadImage(imageData: Data) async throws -> String
    
    /// Gets coordinates for an address via geocoding
    /// - Parameter address: The address to geocode
    /// - Returns: The geographic coordinates
    /// - Throws: Error if geocoding fails
    func getCoordinatesForAddress(_ address: String) async throws -> CLLocationCoordinate2D
}
