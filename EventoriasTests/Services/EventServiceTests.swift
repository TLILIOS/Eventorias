// 
// EventServiceTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
import CoreLocation
import UIKit
@testable import Eventorias

class EventServiceTests: XCTestCase {
    
    var mockService: MockEventService!
    
    override func setUp() {
        super.setUp()
        mockService = MockEventService()
    }
    
    override func tearDown() {
        mockService = nil
        super.tearDown()
    }
    
    // Create sample events for testing
    private func createSampleEvents() -> [Event] {
        let now = Date()
        return [
            Event(
                id: "1",
                title: "Concert de musique",
                description: "Un concert exceptionnel",
                date: now.addingTimeInterval(60*60*24), // 1 day from now
                location: "Paris",
                organizer: "Organizer 1",
                organizerImageURL: nil,
                imageURL: nil,
                category: "Musique",
                tags: ["concert", "musique"],
                createdAt: now
            ),
            Event(
                id: "2",
                title: "Exposition d'art",
                description: "Une exposition unique",
                date: now.addingTimeInterval(60*60*48), // 2 days from now
                location: "Lyon",
                organizer: "Organizer 2",
                organizerImageURL: nil,
                imageURL: nil,
                category: "Art",
                tags: ["exposition", "art"],
                createdAt: now
            ),
            Event(
                id: "3",
                title: "Conférence tech",
                description: "Une conférence sur les nouvelles technologies",
                date: now.addingTimeInterval(60*60*72), // 3 days from now
                location: "Bordeaux",
                organizer: "Organizer 3",
                organizerImageURL: nil,
                imageURL: nil,
                category: "Technologie",
                tags: ["tech", "conférence"],
                createdAt: now
            )
        ]
    }
    
    func testFetchEvents() async {
        // Setup sample events
        let sampleEvents = createSampleEvents()
        mockService.mockEvents = sampleEvents
        
        do {
            let events = try await mockService.fetchEvents()
            
            // Verify method was called
            XCTAssertTrue(mockService.fetchEventsCalled)
            
            // Verify returned data
            XCTAssertEqual(events.count, sampleEvents.count)
            XCTAssertEqual(events[0].id, "1")
            XCTAssertEqual(events[1].id, "2")
            XCTAssertEqual(events[2].id, "3")
        } catch {
            XCTFail("fetchEvents should not throw an error: \(error)")
        }
    }
    
    func testFetchEventsFailure() async {
        // Setup error
        let expectedError = NSError(domain: "EventServiceError", code: 1, 
                                    userInfo: [NSLocalizedDescriptionKey: "Failed to fetch events"])
        mockService.mockError = expectedError
        
        do {
            _ = try await mockService.fetchEvents()
            XCTFail("fetchEvents should throw an error")
        } catch {
            // Verify method was called
            XCTAssertTrue(mockService.fetchEventsCalled)
            
            // Verify the error
            let nsError = error as NSError
            XCTAssertEqual(nsError.domain, "EventServiceError")
            XCTAssertEqual(nsError.code, 1)
        }
    }
    
    func testSearchEvents() async {
        // Setup sample events
        let sampleEvents = createSampleEvents()
        mockService.mockEvents = sampleEvents
        
        do {
            let events = try await mockService.searchEvents(query: "art")
            
            // Verify method was called with the right parameters
            XCTAssertTrue(mockService.searchEventsCalled)
            XCTAssertEqual(mockService.lastSearchQuery, "art")
            
            // Because our mock implementation does a simple filter, we should only get events with "art" in the title
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events[0].id, "2")
            XCTAssertEqual(events[0].title, "Exposition d'art")
        } catch {
            XCTFail("searchEvents should not throw an error: \(error)")
        }
    }
    
    func testFilterEventsByCategory() async {
        // Setup sample events
        let sampleEvents = createSampleEvents()
        mockService.mockEvents = sampleEvents
        
        do {
            let events = try await mockService.filterEventsByCategory(category: "Musique")
            
            // Verify method was called with the right parameters
            XCTAssertTrue(mockService.filterEventsByCategoryCalled)
            XCTAssertEqual(mockService.lastCategory, "Musique")
            
            // Because our mock implementation does a simple filter, we should only get events with category "Musique"
            XCTAssertEqual(events.count, 1)
            XCTAssertEqual(events[0].id, "1")
            XCTAssertEqual(events[0].category, "Musique")
        } catch {
            XCTFail("filterEventsByCategory should not throw an error: \(error)")
        }
    }
    
    func testGetEventsSortedByDateAscending() async {
        // Setup sample events
        let sampleEvents = createSampleEvents()
        mockService.mockEvents = sampleEvents
        
        do {
            let events = try await mockService.getEventsSortedByDate(ascending: true)
            
            // Verify method was called with the right parameters
            XCTAssertTrue(mockService.getEventsSortedByDateCalled)
            XCTAssertTrue(mockService.lastSortAscending ?? false)
            
            // Verify the events are sorted correctly (ascending by date)
            XCTAssertEqual(events.count, 3)
            XCTAssertEqual(events[0].id, "1") // 1 day from now
            XCTAssertEqual(events[1].id, "2") // 2 days from now
            XCTAssertEqual(events[2].id, "3") // 3 days from now
        } catch {
            XCTFail("getEventsSortedByDate should not throw an error: \(error)")
        }
    }
    
    func testGetEventsSortedByDateDescending() async {
        // Setup sample events
        let sampleEvents = createSampleEvents()
        mockService.mockEvents = sampleEvents
        
        do {
            let events = try await mockService.getEventsSortedByDate(ascending: false)
            
            // Verify method was called with the right parameters
            XCTAssertTrue(mockService.getEventsSortedByDateCalled)
            XCTAssertFalse(mockService.lastSortAscending ?? true)
            
            // Verify the events are sorted correctly (descending by date)
            XCTAssertEqual(events.count, 3)
            XCTAssertEqual(events[0].id, "3") // 3 days from now
            XCTAssertEqual(events[1].id, "2") // 2 days from now
            XCTAssertEqual(events[2].id, "1") // 1 day from now
        } catch {
            XCTFail("getEventsSortedByDate should not throw an error: \(error)")
        }
    }
    
    func testIsEventsCollectionEmpty() async {
        mockService.mockIsEmpty = true
        
        do {
            let isEmpty = try await mockService.isEventsCollectionEmpty()
            
            // Verify method was called
            XCTAssertTrue(mockService.isEventsCollectionEmptyCalled)
            
            // Verify returned data
            XCTAssertTrue(isEmpty)
        } catch {
            XCTFail("isEventsCollectionEmpty should not throw an error: \(error)")
        }
    }
    
    func testCreateEvent() async {
        // Setup for success
        mockService.mockEventId = "new-event-id"
        
        let title = "New Event"
        let description = "Event Description"
        let date = Date()
        let location = "Event Location"
        let imageURL = "https://example.com/test-image.jpg" 
        
        do {
            let eventId = try await mockService.createEvent(
                title: title,
                description: description,
                date: date,
                location: location,
                imageURL: imageURL // Changer 'image:' en 'imageURL:'
            )
            
            // Verify method was called with the right parameters
            XCTAssertTrue(mockService.createEventCalled)
            XCTAssertEqual(mockService.lastEventTitle, title)
            XCTAssertEqual(mockService.lastEventDescription, description)
            XCTAssertEqual(mockService.lastEventDate, date)
            XCTAssertEqual(mockService.lastEventLocation, location)
            XCTAssertEqual(mockService.lastImageURL, imageURL) // Changer en lastImageURL
            
            // Verify returned data
            XCTAssertEqual(eventId, "new-event-id")
        } catch {
            XCTFail("createEvent should not throw an error: \(error)")
        }
    }
    

    func testGetCoordinatesForAddress() async {
        // Setup expected coordinates
        let expectedCoordinates = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
        mockService.mockCoordinates = expectedCoordinates
        
        let address = "Paris, France"
        
        do {
            let coordinates = try await mockService.getCoordinatesForAddress(address)
            
            // Verify method was called with the right parameters
            XCTAssertTrue(mockService.getCoordinatesForAddressCalled)
            XCTAssertEqual(mockService.lastEventLocation, address)
            
            // Verify returned data
            XCTAssertEqual(coordinates.latitude, expectedCoordinates.latitude, accuracy: 0.0001)
            XCTAssertEqual(coordinates.longitude, expectedCoordinates.longitude, accuracy: 0.0001)
        } catch {
            XCTFail("getCoordinatesForAddress should not throw an error: \(error)")
        }
    }
}
