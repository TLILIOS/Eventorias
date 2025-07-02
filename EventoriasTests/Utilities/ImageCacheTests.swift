//
//  ImageCacheTests.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 28/06/2025.
//

import XCTest
import SwiftUI
@testable import Eventorias
@MainActor
final class ImageCacheTests: XCTestCase {
    
    func testImageCacheStorageAndRetrieval() {
        // Arrange
        let cache = ImageCache.shared
        let testImage = UIImage(systemName: "star.fill")!
        let testKey = "test-key-\(UUID().uuidString)"
        
        // Act - Store
        cache.store(testImage, forKey: testKey)
        
        // Assert - Retrieve
        let retrievedImage = cache.retrieve(forKey: testKey)
        XCTAssertNotNil(retrievedImage, "L'image devrait être récupérée du cache")
    }
    
    func testImageCacheRemoval() {
        // Arrange
        let cache = ImageCache.shared
        let testImage = UIImage(systemName: "star.fill")!
        let testKey = "test-key-\(UUID().uuidString)"
        
        // Act - Store then Remove
        cache.store(testImage, forKey: testKey)
        cache.removeImage(forKey: testKey)
        
        // Assert
        let retrievedImage = cache.retrieve(forKey: testKey)
        XCTAssertNil(retrievedImage, "L'image devrait être supprimée du cache")
    }
    
    func testImageCacheClear() {
        // Arrange
        let cache = ImageCache.shared
        let testImage = UIImage(systemName: "star.fill")!
        let testKey1 = "test-key-1-\(UUID().uuidString)"
        let testKey2 = "test-key-2-\(UUID().uuidString)"
        
        // Act - Store multiple then Clear
        cache.store(testImage, forKey: testKey1)
        cache.store(testImage, forKey: testKey2)
        cache.clearCache()
        
        // Assert
        XCTAssertNil(cache.retrieve(forKey: testKey1), "L'image 1 devrait être supprimée après clearCache")
        XCTAssertNil(cache.retrieve(forKey: testKey2), "L'image 2 devrait être supprimée après clearCache")
    }
    
    override func tearDown() {
        // Nettoyer le cache après chaque test
        ImageCache.shared.clearCache()
        super.tearDown()
    }
}
