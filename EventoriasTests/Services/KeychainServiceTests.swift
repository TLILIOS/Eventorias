//
//  KeychainServiceTests.swift
//  EventoriasTests
//
//  Created on 27/06/2025.
//

import XCTest
@testable import Eventorias
@MainActor
class KeychainServiceTests: XCTestCase {
    
    // MARK: - Properties
    
    var keychainService: KeychainService!
    let testAccount = "testAccount"
    let testData = "testData123"
    let testService = "com.test.eventorias"
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        // Utilisation d'un identifiant de service spécifique aux tests
        keychainService = KeychainService(service: testService, accessibility: kSecAttrAccessibleWhenUnlocked, debug: true)
        
        // S'assurer que le keychain est propre avant chaque test
        try? keychainService.delete(for: testAccount)
    }
    
    override func tearDown() {
        // Nettoyer après chaque test
        try? keychainService.delete(for: testAccount)
        keychainService = nil
        super.tearDown()
    }
    
    // MARK: - Test Save Method
    
    func testSaveSuccess() {
        // Given
        // Configuration déjà effectuée dans setUp
        
        // When & Then
        XCTAssertNoThrow(try keychainService.save(testData, for: testAccount), "La sauvegarde devrait réussir")
        
        // Vérification additionnelle pour confirmer que les données ont été sauvegardées
        XCTAssertTrue(keychainService.exists(for: testAccount), "Les données devraient exister après sauvegarde")
    }
    
    func testSaveWithEmptyData() {
        // Given
        let emptyData = ""
        
        // When & Then
        XCTAssertNoThrow(try keychainService.save(emptyData, for: testAccount), "La sauvegarde de données vides devrait réussir")
        
        // Vérification que les données vides ont été sauvegardées
        XCTAssertTrue(keychainService.exists(for: testAccount), "Les données vides devraient exister après sauvegarde")
    }
    
    func testSaveOverwrite() {
        // Given
        let initialData = "initialData"
        let newData = "newData"
        
        // When
        // Sauvegarde initiale
        XCTAssertNoThrow(try keychainService.save(initialData, for: testAccount))
        
        // Seconde sauvegarde (devrait écraser la première)
        XCTAssertNoThrow(try keychainService.save(newData, for: testAccount))
        
        // Then
        // Vérifier que les nouvelles données ont été sauvegardées
        do {
            let retrievedData = try keychainService.retrieve(for: testAccount)
            XCTAssertEqual(retrievedData, newData, "Les nouvelles données devraient avoir écrasé les anciennes")
        } catch {
            XCTFail("La récupération a échoué avec l'erreur: \(error)")
        }
    }
    
    // MARK: - Test Update Method
    
    func testUpdateExistingItem() {
        // Given
        let initialData = "initialData"
        let updatedData = "updatedData"
        
        // When
        // Sauvegarde initiale
        XCTAssertNoThrow(try keychainService.save(initialData, for: testAccount))
        
        // Mise à jour
        XCTAssertNoThrow(try keychainService.update(updatedData, for: testAccount))
        
        // Then
        // Vérifier que les données ont été mises à jour
        do {
            let retrievedData = try keychainService.retrieve(for: testAccount)
            XCTAssertEqual(retrievedData, updatedData, "Les données devraient avoir été mises à jour")
        } catch {
            XCTFail("La récupération a échoué avec l'erreur: \(error)")
        }
    }
    
    func testUpdateNonExistingItem() {
        // Given
        let newData = "newData"
        
        // When & Then
        // La mise à jour d'un élément inexistant devrait créer l'élément
        XCTAssertNoThrow(try keychainService.update(newData, for: testAccount))
        
        // Vérifier que les données ont été créées
        do {
            let retrievedData = try keychainService.retrieve(for: testAccount)
            XCTAssertEqual(retrievedData, newData, "Les données devraient avoir été créées lors de la mise à jour")
        } catch {
            XCTFail("La récupération a échoué avec l'erreur: \(error)")
        }
    }
    
    // MARK: - Test Retrieve Method
    
    func testRetrieveSuccess() {
        // Given
        XCTAssertNoThrow(try keychainService.save(testData, for: testAccount))
        
        // When & Then
        do {
            let retrievedData = try keychainService.retrieve(for: testAccount)
            XCTAssertEqual(retrievedData, testData, "Les données récupérées devraient correspondre aux données sauvegardées")
        } catch {
            XCTFail("La récupération a échoué avec l'erreur: \(error)")
        }
    }
    
    func testRetrieveNonExistingItem() {
        // Given
        // Pas de données sauvegardées
        
        // When & Then
        // La récupération d'un élément inexistant devrait échouer avec KeychainError.itemNotFound
        XCTAssertThrowsError(try keychainService.retrieve(for: testAccount)) { error in
            guard let keychainError = error as? KeychainError else {
                XCTFail("Erreur de type incorrect")
                return
            }
            XCTAssertEqual(keychainError, KeychainError.itemNotFound, "L'erreur devrait être 'itemNotFound'")
        }
    }
    
    // MARK: - Test Delete Method
    
    func testDeleteExistingItem() {
        // Given
        XCTAssertNoThrow(try keychainService.save(testData, for: testAccount))
        
        // When
        XCTAssertNoThrow(try keychainService.delete(for: testAccount))
        
        // Then
        XCTAssertFalse(keychainService.exists(for: testAccount), "L'élément devrait être supprimé")
    }
    
    func testDeleteNonExistingItem() {
        // Given
        // Pas de données sauvegardées
        
        // When & Then
        // La suppression d'un élément inexistant ne devrait pas lever d'erreur
        XCTAssertNoThrow(try keychainService.delete(for: testAccount))
    }
    
    // MARK: - Test Exists Method
    
    func testExistsWithExistingItem() {
        // Given
        XCTAssertNoThrow(try keychainService.save(testData, for: testAccount))
        
        // When & Then
        XCTAssertTrue(keychainService.exists(for: testAccount), "L'élément devrait exister")
    }
    
    func testExistsWithNonExistingItem() {
        // Given
        // Pas de données sauvegardées
        
        // When & Then
        XCTAssertFalse(keychainService.exists(for: testAccount), "L'élément ne devrait pas exister")
    }
    
    // MARK: - Edge Cases
    
    func testWithSpecialCharacters() {
        // Given
        let specialData = "!@#$%^&*()_+-=[]{}|;':\",./<>?"
        let specialAccount = "account!@#"
        
        // When & Then
        XCTAssertNoThrow(try keychainService.save(specialData, for: specialAccount))
        
        do {
            let retrievedData = try keychainService.retrieve(for: specialAccount)
            XCTAssertEqual(retrievedData, specialData, "Les caractères spéciaux devraient être gérés correctement")
        } catch {
            XCTFail("La récupération a échoué avec l'erreur: \(error)")
        }
        
        // Cleanup
        try? keychainService.delete(for: specialAccount)
    }
    
    func testWithVeryLongString() {
        // Given
        let longData = String(repeating: "a", count: 10000) // Une chaîne très longue
        
        // When & Then
        XCTAssertNoThrow(try keychainService.save(longData, for: testAccount))
        
        do {
            let retrievedData = try keychainService.retrieve(for: testAccount)
            XCTAssertEqual(retrievedData, longData, "Les données longues devraient être gérées correctement")
        } catch {
            XCTFail("La récupération a échoué avec l'erreur: \(error)")
        }
    }
}
