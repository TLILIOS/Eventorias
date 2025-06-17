//
// MockEventViewModel.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import Foundation
import SwiftUI
import Combine
@testable import Eventorias

class MockEventViewModel: ObservableObject, EventViewModelProtocol {
    
    // Published properties pour simuler EventViewModel
    @Published var events: [Event] = []
    @Published var filteredEvents: [Event] = []
    @Published var searchText: String = ""
    @Published var sortOption: EventViewModel.SortOption = .dateAscending
    
    // MARK: - Required EventViewModelProtocol Properties
    @Published var eventTitle: String = ""
    @Published var eventDescription: String = ""
    @Published var eventDate: Date = Date()
    @Published var eventAddress: String = ""
    @Published var eventImage: UIImage? = nil
    @Published var imageUploadState: EventViewModel.ImageUploadState = .ready
    @Published var eventCreationSuccess: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String = ""
    @Published var showingError: Bool = false
    
    // Tracking properties pour les tests
    var addEventCalled = false
    var updateEventCalled = false
    var deleteEventCalled = false
    var loadEventsCalled = false
    var createEventCalled = false
    var shouldSucceed = true
    var mockError: Error?
    
    func addEvent(_ event: Event) {
        addEventCalled = true
        if shouldSucceed {
            events.append(event)
            filteredEvents = events
        }
    }
    
    func deleteEvent(withId id: String) {
        deleteEventCalled = true
        if shouldSucceed {
            if let index = events.firstIndex(where: { $0.id == id }) {
                events.remove(at: index)
                filteredEvents = events
            }
        }
    }
    
    func loadEvents() {
        loadEventsCalled = true
    }
    
    func fetchEvents() async {
        loadEventsCalled = true
        if shouldSucceed {
            // Simulate successful loading
            isLoading = false
            showingError = false
        } else if let error = mockError {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    func refreshEvents() async {
        await fetchEvents()
    }
    
    func updateSortOption(_ newOption: EventViewModel.SortOption) async {
        sortOption = newOption
    }
    
    func dismissError() {
        showingError = false
        errorMessage = ""
    }
    
    func resetEventFormFields() {
        eventTitle = ""
        eventDescription = ""
        eventDate = Date()
        eventAddress = ""
        eventImage = nil
        imageUploadState = .ready
        eventCreationSuccess = false
    }
    
    // MARK: - Required EventViewModelProtocol Methods
    /// Implementation of required protocol method
    /// - Returns: true if event creation succeeded, false otherwise
    @discardableResult
    func createEvent() async -> Bool {
        createEventCalled = true
        
        if shouldSucceed {
            eventCreationSuccess = true
            // Simulate adding the created event to the list
            let newEvent = Event(
                id: UUID().uuidString,
                title: eventTitle,
                description: eventDescription,
                date: eventDate,
                location: eventAddress,
                organizer: "test_organizer",
                organizerImageURL: nil,
                imageURL: nil,
                category: "test",
                tags: [],
                createdAt: Date()
            )
            events.append(newEvent)
            resetEventFormFields()
            return true
        } else {
            eventCreationSuccess = false
            if let error = mockError {
                errorMessage = error.localizedDescription
                showingError = true
            }
            return false
        }
    }
}
