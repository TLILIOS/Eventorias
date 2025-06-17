import Foundation
import UIKit
import CoreLocation
@testable import Eventorias

class MockEventService: EventService {
    // Tracking properties
    var fetchEventsCalled = false
    var searchEventsCalled = false
    var filterEventsByCategoryCalled = false
    var getEventsSortedByDateCalled = false
    var addSampleEventsCalled = false
    var isEventsCollectionEmptyCalled = false
    var createEventCalled = false
    var uploadImageCalled = false
    var getCoordinatesForAddressCalled = false
    
    // Mock responses
    var mockEvents: [Event] = []
    var mockIsEmpty = false
    var mockEventId = "mock_event_id"
    var mockImageURL: String? = "https://example.com/mock_image.jpg"
    var mockCoordinates = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522) // Paris coordinates
    var mockError: Error?
    
    // Result-based mocking for better test control
    var fetchEventsResult: Result<[Event], Error>?
    
    // Search parameters
    var lastSearchQuery: String?
    var lastCategory: String?
    var lastSortAscending: Bool?
    var lastEventTitle: String?
    var lastEventDescription: String?
    var lastEventDate: Date?
    var lastEventLocation: String?
    var lastImageURL: String?
    
    // Override methods
    override func fetchEvents() async throws -> [Event] {
        fetchEventsCalled = true
        
        // Use fetchEventsResult if available, otherwise fall back to the original implementation
        if let result = fetchEventsResult {
            switch result {
            case .success(let events):
                return events
            case .failure(let error):
                throw error
            }
        }
        
        // Original implementation as fallback
        if let error = mockError {
            throw error
        }
        
        return mockEvents
    }
    
    override func searchEvents(query: String) async throws -> [Event] {
        searchEventsCalled = true
        lastSearchQuery = query
        
        if let error = mockError {
            throw error
        }
        
        return mockEvents.filter { $0.title.lowercased().contains(query.lowercased()) }
    }
    
    override func filterEventsByCategory(category: String) async throws -> [Event] {
        filterEventsByCategoryCalled = true
        lastCategory = category
        
        if let error = mockError {
            throw error
        }
        
        return mockEvents.filter { $0.category == category }
    }
    
    override func getEventsSortedByDate(ascending: Bool) async throws -> [Event] {
        getEventsSortedByDateCalled = true
        lastSortAscending = ascending
        
        if let error = mockError {
            throw error
        }
        
        return mockEvents.sorted { lhs, rhs in
            ascending ? lhs.date < rhs.date : lhs.date > rhs.date
        }
    }
    
    override func addSampleEvents() async throws {
        addSampleEventsCalled = true
        
        if let error = mockError {
            throw error
        }
    }
    
    override func isEventsCollectionEmpty() async throws -> Bool {
        isEventsCollectionEmptyCalled = true
        
        if let error = mockError {
            throw error
        }
        
        return mockIsEmpty
    }
    
    override func createEvent(title: String, description: String, date: Date, location: String, imageURL: String?) async throws -> String {
        createEventCalled = true
        lastEventTitle = title
        lastEventDescription = description
        lastEventDate = date
        lastEventLocation = location
        lastImageURL = imageURL
        
        if let error = mockError {
            throw error
        }
        
        return mockEventId
    }
    
    // CORRECTION: Assurer que mockImageURL est retourné correctement
    override func uploadImage(imageData: Data) async throws -> String {
        uploadImageCalled = true
        print("🔍 MockEventService.uploadImage called")
        print("  - imageData size: \(imageData.count)")
        print("  - mockImageURL: \(String(describing: mockImageURL))")
        
        if let error = mockError {
            print("  - throwing error: \(error)")
            throw error
        }
        
        guard let imageURL = mockImageURL else {
            let error = NSError(domain: "MockError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No mock image URL provided"])
            print("  - throwing no URL error")
            throw error
        }
        
        print("  - returning URL: \(imageURL)")
        return imageURL
    }

    
    override func getCoordinatesForAddress(_ address: String) async throws -> CLLocationCoordinate2D {
        getCoordinatesForAddressCalled = true
        lastEventLocation = address
        
        if let error = mockError {
            throw error
        }
        
        return mockCoordinates
    }
}
