

import XCTest
import Combine
@testable import Eventorias

@MainActor
final class EventViewModelTests: XCTestCase {
    var mockEventService: MockEventService!
    var sut: EventViewModel!
    private var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockEventService = MockEventService()
        sut = EventViewModel(eventService: mockEventService)
        cancellables = []
    }
    
    override func tearDown() {
        mockEventService = nil
        sut = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    private func createSampleEvents() -> [Event] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            Event(
                id: "event1",
                title: "Concert Rock",
                description: "Un super concert rock",
                date: calendar.date(byAdding: .day, value: 1, to: today)!,
                location: "Paris",
                organizer: "user1",
                organizerImageURL: nil,
                imageURL: "https://example.com/image1.jpg",
                category: "music",
                tags: [],
                createdAt: today
            ),
            Event(
                id: "event2",
                title: "Exposition Art",
                description: "Une exposition d'art contemporain",
                date: calendar.date(byAdding: .day, value: -1, to: today)!,
                location: "Lyon",
                organizer: "user2",
                organizerImageURL: nil,
                imageURL: "https://example.com/image2.jpg",
                category: "art",
                tags: [],
                createdAt: today
            ),
            Event(
                id: "event3",
                title: "Match de football",
                description: "Un match de football important",
                date: calendar.date(byAdding: .day, value: 5, to: today)!,
                location: "Marseille",
                organizer: "user3",
                organizerImageURL: nil,
                imageURL: "https://example.com/image3.jpg",
                category: "sport",
                tags: [],
                createdAt: today
            )
        ]
    }
    
    // MARK: - Tests
    func testInitialization() {
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.searchText, "")
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertFalse(sut.showingError)
        XCTAssertEqual(sut.sortOption, .dateAscending)
        XCTAssertTrue(sut.events.isEmpty)
    }
    
    func testFetchEvents() async {
        // Arrange
        let sampleEvents = createSampleEvents()
        mockEventService.mockEvents = sampleEvents
        mockEventService.mockIsEmpty = false
        
        // Act
        await sut.fetchEvents()
        
        // Assert
        XCTAssertEqual(sut.events.count, sampleEvents.count)
        XCTAssertTrue(mockEventService.isEventsCollectionEmptyCalled)
        XCTAssertTrue(mockEventService.getEventsSortedByDateCalled)
        XCTAssertFalse(sut.isLoading)
        XCTAssertFalse(sut.showingError)
    }
    
    func testFetchEvents_WithEmptyCollection() async {
        // Arrange
        mockEventService.mockIsEmpty = true
        
        // Act
        await sut.fetchEvents()
        
        // Assert
        XCTAssertTrue(mockEventService.isEventsCollectionEmptyCalled)
        XCTAssertTrue(mockEventService.addSampleEventsCalled)
        XCTAssertTrue(mockEventService.getEventsSortedByDateCalled)
    }
    
    func testFetchEvents_WithError() async {
        // Arrange
        let errorMessage = "Network error"
        mockEventService.mockError = NSError(domain: "test", code: 0, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        
        // Act
        await sut.fetchEvents()
        
        // Assert
        XCTAssertEqual(sut.errorMessage, errorMessage)
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.isLoading)
    }
    
    func testFilteredEvents_EmptySearchText() {
        // Arrange
        let sampleEvents = createSampleEvents()
        sut.events = sampleEvents
        sut.searchText = ""
        
        // Act
        let filteredEvents = sut.filteredEvents
        
        // Assert
        XCTAssertEqual(filteredEvents.count, sampleEvents.count)
    }
    
    func testFilteredEvents_WithSearchText() {
        // Arrange
        sut.events = createSampleEvents()
        
        // Act - Search by title
        sut.searchText = "rock"
        
        // Assert
        XCTAssertEqual(sut.filteredEvents.count, 1)
        XCTAssertEqual(sut.filteredEvents.first?.title, "Concert Rock")
        
        // Act - Search by description
        sut.searchText = "football"
        
        // Assert
        XCTAssertEqual(sut.filteredEvents.count, 1)
        XCTAssertEqual(sut.filteredEvents.first?.title, "Match de football")
        
        // Act - Search by location
        sut.searchText = "lyon"
        
        // Assert
        XCTAssertEqual(sut.filteredEvents.count, 1)
        XCTAssertEqual(sut.filteredEvents.first?.title, "Exposition Art")
        
        // Act - Search with no results
        sut.searchText = "tennis"
        
        // Assert
        XCTAssertTrue(sut.filteredEvents.isEmpty)
    }
    
    func testSortEventsAscending() {
        // Given
        let events = createSampleEvents()
        mockEventService.mockEvents = events
        let expectation = XCTestExpectation(description: "Events sorted")
        
        // When
        Task {
            await sut.fetchEvents()
            sut.sortOption = .dateAscending
            
            // Then
            let sortedDates = events.map { $0.date }.sorted()
            XCTAssertEqual(sut.filteredEvents.map { $0.date }, sortedDates)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testSortEventsDescending() {
        // Given
        let events = createSampleEvents()
        mockEventService.mockEvents = events
        let expectation = XCTestExpectation(description: "Events sorted descending")
        
        // When
        Task {
            await sut.fetchEvents()
            sut.sortOption = .dateDescending
            
            // Then
            let sortedDates = events.map { $0.date }.sorted(by: >)
            XCTAssertEqual(sut.filteredEvents.map { $0.date }, sortedDates)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testCreateEvent_Success() async {
        // Arrange
        sut.eventTitle = "Test Event"
        sut.eventDescription = "Test Description"
        sut.eventDate = Date()
        sut.eventAddress = "Test Location"
        sut.eventImage = nil
        sut.eventCreationSuccess = false
        
        mockEventService.mockError = nil
        mockEventService.mockIsEmpty = false
        mockEventService.mockEvents = []
        
        // Act
        let success = await sut.createEvent()
        
        // Debug info
        print("🔍 Success returned: \(success)")
        print("🔍 eventCreationSuccess: \(sut.eventCreationSuccess)")
        print("🔍 showingError: \(sut.showingError)")
        print("🔍 errorMessage: '\(sut.errorMessage)'")
        
        // Assert
        XCTAssertTrue(success, "createEvent should return true on success")
        XCTAssertTrue(sut.eventCreationSuccess,
            "eventCreationSuccess should be true. Error: '\(sut.errorMessage)', ShowingError: \(sut.showingError)")
        XCTAssertTrue(mockEventService.createEventCalled)
    }

    
    func testCreateEvent_EmptyTitle() async {
        // Arrange
        sut.eventTitle = ""
        sut.eventDescription = "Test Description"
        sut.eventDate = Date()
        sut.eventAddress = "Test Location"
        
        // Act
        await sut.createEvent()
        
        // Assert
        XCTAssertFalse(mockEventService.createEventCalled)
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.eventCreationSuccess)
    }
    
    func testCreateEvent_EmptyAddress() async {
        // Arrange
        sut.eventTitle = "Test Event"
        sut.eventDescription = "Test Description"
        sut.eventDate = Date()
        sut.eventAddress = ""
        
        // Act
        await sut.createEvent()
        
        // Assert
        XCTAssertFalse(mockEventService.createEventCalled)
        XCTAssertTrue(sut.showingError)
        XCTAssertFalse(sut.eventCreationSuccess)
    }
    
    func testCreateEvent_WithExpectation() async {
        // Arrange
        let expectation = XCTestExpectation(description: "Event creation completed")
        
        sut.eventTitle = "Test Event"
        sut.eventDescription = "Test Description"
        sut.eventDate = Date()
        sut.eventAddress = "Test Location"
        sut.eventImage = nil
        
        mockEventService.mockError = nil
        mockEventService.mockIsEmpty = false
        mockEventService.mockEvents = []
        
        // Act
        Task {
            let success = await sut.createEvent()
            XCTAssertTrue(success)
            XCTAssertTrue(sut.eventCreationSuccess)
            expectation.fulfill()
        }
        
        // Wait
        await fulfillment(of: [expectation], timeout: 2.0)
    }


    func testResetEventFormFields() {
        // Arrange
        sut.eventTitle = "Test Event"
        sut.eventDescription = "Test Description"
        sut.eventDate = Date()
        sut.eventAddress = "Test Location"
        sut.eventImage = UIImage()
        sut.eventCreationSuccess = true
        sut.imageUploadState = .success(url: "test")
        
        // Act
        sut.resetEventFormFields()
        
        // Assert
        XCTAssertEqual(sut.eventTitle, "")
        XCTAssertEqual(sut.eventDescription, "")
        XCTAssertEqual(sut.eventAddress, "")
        XCTAssertNil(sut.eventImage)
        
        if case .ready = sut.imageUploadState {
            XCTAssertTrue(true) // ImageUploadState est bien .ready
        } else {
            XCTFail("ImageUploadState devrait être .ready")
        }
    }
    
    func testDismissError() {
        // Arrange
        sut.errorMessage = "Test Error"
        sut.showingError = true
        
        // Act
        sut.dismissError()
        
        // Assert
        XCTAssertEqual(sut.errorMessage, "")
        XCTAssertFalse(sut.showingError)
    }
    
    // MARK: - Test Image Upload States
    func testImageUploadState_UploadOnly() async {
        // Arrange
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let testImage = renderer.image { ctx in
            UIColor.blue.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        sut.eventImage = testImage
        mockEventService.mockImageURL = "https://test-image-url.com/image.jpg"
        
        // Act - Test uniquement l'upload
        do {
            let imageURL = try await sut.uploadEventImage()
            
            // Assert
            XCTAssertEqual(imageURL, "https://test-image-url.com/image.jpg")
            XCTAssertEqual(sut.imageUploadState, .success(url: "https://test-image-url.com/image.jpg"))
        } catch {
            XCTFail("Upload should succeed: \(error)")
        }
    }

    
    func testImageUploadState_FailureState() async {
        // Arrange
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 100, height: 100))
        let testImage = renderer.image { ctx in
            UIColor.red.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 100, height: 100))
        }
        
        sut.eventTitle = "Event With Image"
        sut.eventAddress = "Some Location"
        sut.eventImage = testImage
        
        let errorMessage = "Upload failed due to network error"
        mockEventService.mockError = NSError(domain: "test", code: 500, 
                                         userInfo: [NSLocalizedDescriptionKey: errorMessage])
        
        let expectation = XCTestExpectation(description: "Image upload failure state")
        
        // Act
        Task {
            let success = await sut.createEvent()
            
            // Assert
            XCTAssertFalse(success)
            
            // Check if imageUploadState is failure with the correct error message
            switch sut.imageUploadState {
            case .failure(let error):
                XCTAssertEqual(error, errorMessage)
            default:
                XCTFail("Expected failure state but got \(sut.imageUploadState)")
            }
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
    
    // MARK: - Test Computed Properties
    func testIsFormValid() {
        // Given - Invalid form (empty title)
        sut.eventTitle = ""
        sut.eventAddress = "Location"
        
        // Then
        XCTAssertFalse(sut.isFormValid)
        
        // Given - Invalid form (empty address)
        sut.eventTitle = "Title"
        sut.eventAddress = ""
        
        // Then
        XCTAssertFalse(sut.isFormValid)
        
        // Given - Valid form
        sut.eventTitle = "Title"
        sut.eventAddress = "Location"
        
        // Then
        XCTAssertTrue(sut.isFormValid)
        
        // Given - Whitespace-only values
        sut.eventTitle = "   "
        sut.eventAddress = "Location"
        
        // Then
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testHasEvents_AndEmptyStateMessage() {
        // Given - No events
        sut.events = []
        
        // Then
        XCTAssertFalse(sut.hasEvents)
        XCTAssertEqual(sut.emptyStateMessage, "Aucun événement disponible")
        
        // Given - With events
        sut.events = createSampleEvents()
        
        // Then
        XCTAssertTrue(sut.hasEvents)
        
        // Given - With search but no results
        sut.searchText = "something nonexistent"
        
        // Then
        XCTAssertEqual(sut.emptyStateMessage, "Aucun résultat pour \"something nonexistent\"")
    }
    
    func testIsSearchActive() {
        // Given - No search
        sut.searchText = ""
        
        // Then
        XCTAssertFalse(sut.isSearchActive)
        
        // Given - With search
        sut.searchText = "test"
        
        // Then
        XCTAssertTrue(sut.isSearchActive)
        
        // Given - Whitespace-only search
        sut.searchText = "   "
        
        // Then
        XCTAssertFalse(sut.isSearchActive)
    }
    
    // MARK: - Complex Filter/Sort Combinations
    func testFilterAndSortCombination() async {
        // Arrange - Events with different dates and locations
        let calendar = Calendar.current
        let today = Date()
        
        let event1 = EventTestFactory.createEvent(
            id: "event1",
            title: "Paris Event",
            date: calendar.date(byAdding: .day, value: 3, to: today)!,
            location: "Paris"
        )
        
        let event2 = EventTestFactory.createEvent(
            id: "event2",
            title: "Lyon Event",
            date: calendar.date(byAdding: .day, value: 1, to: today)!,
            location: "Lyon"
        )
        
        let event3 = EventTestFactory.createEvent(
            id: "event3",
            title: "Another Paris Event",
            date: calendar.date(byAdding: .day, value: 2, to: today)!,
            location: "Paris"
        )
        
        // Set up service
        mockEventService.mockEvents = [event1, event2, event3]
        
        let expectation = XCTestExpectation(description: "Filter and sort combined")
        
        // Act - Load events, filter by location and sort
        Task {
            await sut.fetchEvents()
            
            // Filter by location
            sut.searchText = "Paris"
            
            // Should have only Paris events, sorted by date ascending
            let filteredAscending = sut.filteredEvents
            XCTAssertEqual(filteredAscending.count, 2, "Should have 2 Paris events")
            XCTAssertEqual(filteredAscending[0].id, "event3", "First should be the earlier Paris event")
            XCTAssertEqual(filteredAscending[1].id, "event1", "Second should be the later Paris event")
            
            // Change sort to descending
            sut.sortOption = .dateDescending
            await sut.updateSortOption(.dateDescending)
            
            // Should still have Paris events, but now sorted by date descending
            XCTAssertEqual(sut.filteredEvents.count, 2, "Still should have 2 Paris events")
            XCTAssertEqual(sut.filteredEvents[0].id, "event1", "First should be the later Paris event")
            XCTAssertEqual(sut.filteredEvents[1].id, "event3", "Second should be the earlier Paris event")
            
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 2.0)
    }
}
