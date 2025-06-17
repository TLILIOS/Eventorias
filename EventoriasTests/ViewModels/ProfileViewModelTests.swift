// 
// ProfileViewModelTests.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import XCTest
import FirebaseAuth
@testable import Eventorias
@MainActor
final class ProfileViewModelTests: XCTestCase {
    var mockAuthViewModel: MockAuthViewModel!
    var sut: ProfileViewModel!
    
    override func setUp() {
        super.setUp()
        mockAuthViewModel = MockAuthViewModel()
        sut = ProfileViewModel(authViewModel: mockAuthViewModel)
        
        // Reset les propriétés publiées pour isolation des tests
        sut.displayName = ""
        sut.email = ""
        sut.avatarUrl = nil
        sut.notificationsEnabled = true
        sut.isLoading = false
        sut.errorMessage = ""
    }
    
    override func tearDown() {
        mockAuthViewModel = nil
        sut = nil
        super.tearDown()
    }
    
    // MARK: - Tests
    
    func testInitialization() {
        // Test que l'initialisation assigne correctement les dépendances
        XCTAssertNotNil(sut)
    }
    
    func testUpdateDisplayName_ValidName() async {
        // Arrange
        let newName = "Test User"
        let expectation = XCTestExpectation(description: "Update display name")
        
        // Act
        await sut.updateDisplayName(newName)
        
        // Attendre que les mises à jour asynchrones se terminent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(sut.displayName, newName)
        XCTAssertFalse(sut.isLoading)
        XCTAssertEqual(sut.errorMessage, "")
    }
    
    func testUpdateDisplayName_EmptyName() async {
        // Arrange
        let emptyName = ""
        let expectation = XCTestExpectation(description: "Update display name with empty value")
        
        // Act
        await sut.updateDisplayName(emptyName)
        
        // Attendre que les mises à jour asynchrones se terminent
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        
        await fulfillment(of: [expectation], timeout: 1.0)
        
        // Assert
        XCTAssertEqual(sut.errorMessage, "Display name cannot be empty")
    }
    
    func testUpdateNotificationPreferences() {
        // Act
        sut.updateNotificationPreferences(enabled: false)
        
        // Assert
        XCTAssertFalse(sut.notificationsEnabled)
        
        // Act again with different value
        sut.updateNotificationPreferences(enabled: true)
        
        // Assert again
        XCTAssertTrue(sut.notificationsEnabled)
    }
    
    func testSignOut() {
        // Act
        sut.signOut()
        
        // Assert
        XCTAssertTrue(mockAuthViewModel.signOutCalled)
    }
}
