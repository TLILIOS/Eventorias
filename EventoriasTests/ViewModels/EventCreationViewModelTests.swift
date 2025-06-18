
// EventCreationViewModelTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
import SwiftUI
import Combine
@testable import Eventorias

@MainActor
final class EventCreationViewModelTests: XCTestCase {
    
    var mockEventViewModel: MockEventViewModel!
    var mockAuthService: MockAuthenticationService!
    var mockStorageService: MockStorageService!
    var mockFirestoreService: MockFirestoreService!
    var sut: EventCreationViewModel!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() {
        super.setUp()
        mockEventViewModel = MockEventViewModel()
        mockAuthService = MockAuthenticationService()
        mockStorageService = MockStorageService()
        mockFirestoreService = MockFirestoreService()
        
        sut = EventCreationViewModel(
            eventViewModel: mockEventViewModel,
            authService: mockAuthService,
            storageService: mockStorageService,
            firestoreService: mockFirestoreService
        )
        
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() {
        cancellables = nil
        mockFirestoreService = nil
        mockStorageService = nil
        mockAuthService = nil
        mockEventViewModel = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests d'authentification mockée
    
    func testCreateEvent_WithMockedAuth() async {
        // Arrange
        sut.eventTitle = "Test Event"
        sut.eventAddress = "Test Address"
        mockAuthService.currentUserDisplayName = "Mock User"
        mockFirestoreService.shouldSucceed = true
        
        // Act
        let result = await sut.createEvent()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertTrue(sut.eventCreationSuccess)
        XCTAssertEqual(mockFirestoreService.createdEvents.count, 1)
        XCTAssertEqual(mockFirestoreService.createdEvents.first?.organizer, "Mock User")
    }
    
    // MARK: - Tests d'upload d'image mockés
    
    func testUploadImage_Success() async {
        // Arrange
        let testImage = createTestImage()
        mockStorageService.shouldSucceed = true
        mockStorageService.mockDownloadURL = "https://test.com/image.jpg"
        
        // Act
        do {
            try await sut.uploadImage(testImage)
            
            // Assert
            XCTAssertEqual(sut.imageUploadState, .success)
            XCTAssertEqual(sut.imageURL, "https://test.com/image.jpg")
        } catch {
            XCTFail("Upload should succeed: \(error)")
        }
    }
    
    func testUploadImage_Failure() async {
        // Arrange
        let testImage = createTestImage()
        mockStorageService.shouldSucceed = false
        mockStorageService.mockError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Upload failed"])
        
        // Act & Assert
        do {
            try await sut.uploadImage(testImage)
            XCTFail("Upload should fail")
        } catch {
            XCTAssertEqual(sut.imageUploadState, .failure)
            XCTAssertTrue(error.localizedDescription.contains("Upload failed"))
        }
    }
    
    // MARK: - Tests d'erreur Firestore
    
    func testCreateEvent_FirestoreError() async {
        // Arrange
        sut.eventTitle = "Test Event"
        sut.eventAddress = "Test Address"
        mockFirestoreService.shouldSucceed = false
        mockFirestoreService.mockError = NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Permission denied"])
        
        // Act
        let result = await sut.createEvent()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertTrue(sut.errorMessage.contains("Permission denied"))
        XCTAssertFalse(sut.eventCreationSuccess)
        XCTAssertEqual(mockFirestoreService.createdEvents.count, 0)
    }
    
    // MARK: - Tests d'intégration complète
    
    func testCreateEvent_WithImageUpload_Success() async {
        // Arrange
        sut.eventTitle = "Event with Image"
        sut.eventAddress = "Test Location"
        sut.eventImage = createTestImage()
        
        mockAuthService.currentUserDisplayName = "Test Organizer"
        mockStorageService.shouldSucceed = true
        mockStorageService.mockDownloadURL = "https://test.com/uploaded-image.jpg"
        mockFirestoreService.shouldSucceed = true
        
        // Act
        let result = await sut.createEvent()
        
        // Assert
        XCTAssertTrue(result)
        XCTAssertTrue(sut.eventCreationSuccess)
        XCTAssertEqual(sut.imageUploadState, .success)
        XCTAssertEqual(sut.imageURL, "https://test.com/uploaded-image.jpg")
        XCTAssertEqual(mockFirestoreService.createdEvents.count, 1)
        
        let createdEvent = mockFirestoreService.createdEvents.first!
        XCTAssertEqual(createdEvent.title, "Event with Image")
        XCTAssertEqual(createdEvent.organizer, "Test Organizer")
        XCTAssertEqual(createdEvent.imageURL, "https://test.com/uploaded-image.jpg")
    }
    
    func testCreateEvent_ImageUploadFailure() async {
        // Arrange
        sut.eventTitle = "Event with Failed Image"
        sut.eventAddress = "Test Location"
        sut.eventImage = createTestImage()
        
        mockStorageService.shouldSucceed = false
        mockStorageService.mockError = NSError(domain: "StorageError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Storage upload failed"])
        
        // Act
        let result = await sut.createEvent()
        
        // Assert
        XCTAssertFalse(result)
        XCTAssertFalse(sut.eventCreationSuccess)
        XCTAssertEqual(sut.imageUploadState, .failure)
        XCTAssertTrue(sut.errorMessage.contains("Storage upload failed"))
        XCTAssertEqual(mockFirestoreService.createdEvents.count, 0) // Aucun événement créé
    }
    
    // MARK: - Helper Methods
    
    private func createTestImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        UIGraphicsBeginImageContext(size)
        defer { UIGraphicsEndImageContext() }
        
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
    }
}
