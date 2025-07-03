// 
// EventTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
@testable import Eventorias

class EventTests: XCTestCase {
    
    // Test the Event struct initialization
    func testEventInitialization() {
        let now = Date()
        let event = Event(
            id: "test-id",
            title: "Test Event",
            description: "Test Description",
            date: now,
            location: "Test Location",
            organizer: "Test Organizer",
            organizerImageURL: "https://example.com/organizer.jpg",
            imageURL: "https://example.com/event.jpg",
            category: .other,
            tags: ["test", "event", "unit test"],
            createdAt: now
        )
        
        XCTAssertEqual(event.id, "test-id")
        XCTAssertEqual(event.title, "Test Event")
        XCTAssertEqual(event.description, "Test Description")
        XCTAssertEqual(event.date, now)
        XCTAssertEqual(event.location, "Test Location")
        XCTAssertEqual(event.organizer, "Test Organizer")
        XCTAssertEqual(event.organizerImageURL, "https://example.com/organizer.jpg")
        XCTAssertEqual(event.imageURL, "https://example.com/event.jpg")
        XCTAssertEqual(event.category, .other)
        XCTAssertEqual(event.tags, ["test", "event", "unit test"])
        XCTAssertEqual(event.createdAt, now)
    }
    
    // Test formattedDate computed property
    func testFormattedDate() {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        let now = Date()
        let expectedString = formatter.string(from: now)
        
        let event = Event(
            id: "test-id",
            title: "Test Event",
            description: "Test Description",
            date: now,
            location: "Test Location",
            organizer: "Test Organizer",
            organizerImageURL: nil,
            imageURL: nil,
            category: .other,
            tags: nil,
            createdAt: now
        )
        
        XCTAssertEqual(event.formattedDate, expectedString)
    }
    
    // Test sample events
    func testSampleEvents() {
        let samples = Event.sampleEvents
        
        // Verify we have the expected number of sample events
        XCTAssertEqual(samples.count, 16)
        
        // Test properties of a few sample events
        XCTAssertEqual(samples[0].id, "2")
        XCTAssertEqual(samples[0].title, "Art exhibition")
        XCTAssertEqual(samples[0].category, .art)
        
        XCTAssertEqual(samples[1].id, "3")
        XCTAssertEqual(samples[1].title, "Tech conference")
        XCTAssertEqual(samples[1].category, .technology)
    }
    
    // Test optional fields
    func testOptionalFields() {
        let event = Event(
            id: "test-id",
            title: "Test Event",
            description: "Test Description",
            date: Date(),
            location: "Test Location",
            organizer: "Test Organizer",
            organizerImageURL: nil,
            imageURL: nil,
            category: .other,
            tags: nil,
            createdAt: Date()
        )
        
        XCTAssertNil(event.organizerImageURL)
        XCTAssertNil(event.imageURL)
        XCTAssertNil(event.tags)
    }
}
