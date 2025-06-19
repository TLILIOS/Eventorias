//
//  MockKeychainService.swift
//  EventoriasTests
//
//  Created by TLiLi Hamdi on 18/06/2025.
//

import Foundation
@testable import Eventorias

/// Mock de KeychainService pour les tests unitaires
class MockKeychainService: KeychainServiceProtocol {
    // Dictionnaire en mémoire pour simuler le stockage Keychain
    private var storage: [String: String] = [:]
    
    // Propriétés de tracking pour les tests
    var saveCalled = false
    var retrieveCalled = false
    var deleteCalled = false
    var existsCalled = false
    
    // Compteurs pour suivre le nombre d'appels à chaque méthode
    var saveCalledCount = 0
    var retrieveCalledCount = 0
    var deleteCalledCount = 0
    var existsCalledCount = 0
    
    // Dernières valeurs utilisées pour les appels
    var lastSavedData: String?
    var lastSavedAccount: String?
    var lastRetrievedAccount: String?
    var lastDeletedAccount: String?
    var lastExistsAccount: String?
    
    // Configuration pour contrôler le comportement du mock
    var shouldFailOnSave = false
    var shouldFailOnDelete = false
    var shouldReturnNilOnRetrieve = false
    
    /// Sauvegarde une donnée dans le mock Keychain
    func save(_ data: String, for account: String) -> Bool {
        saveCalled = true
        saveCalledCount += 1
        lastSavedData = data
        lastSavedAccount = account
        
        if shouldFailOnSave {
            return false
        }
        
        storage[account] = data
        return true
    }
    
    /// Récupère une donnée depuis le mock Keychain
    func retrieve(for account: String) -> String? {
        retrieveCalled = true
        retrieveCalledCount += 1
        lastRetrievedAccount = account
        
        if shouldReturnNilOnRetrieve {
            return nil
        }
        
        return storage[account]
    }
    
    /// Supprime une donnée du mock Keychain
    func delete(for account: String) -> Bool {
        deleteCalled = true
        deleteCalledCount += 1
        lastDeletedAccount = account
        
        if shouldFailOnDelete {
            return false
        }
        
        storage.removeValue(forKey: account)
        return true
    }
    
    /// Vérifie si une donnée existe dans le mock Keychain
    func exists(for account: String) -> Bool {
        existsCalled = true
        existsCalledCount += 1
        lastExistsAccount = account
        
        return storage[account] != nil
    }
    
    // Méthodes utilitaires pour les tests
    
    /// Configure le mock pour réussir toutes les opérations
    func configureForSuccess() {
        shouldFailOnSave = false
        shouldFailOnDelete = false
        shouldReturnNilOnRetrieve = false
        resetTracking()
    }
    
    /// Configure le mock pour échouer aux opérations
    func configureForFailure() {
        shouldFailOnSave = true
        shouldFailOnDelete = true
        shouldReturnNilOnRetrieve = true
        resetTracking()
    }
    
    /// Réinitialise le stockage et les compteurs
    func reset() {
        storage.removeAll()
        resetTracking()
    }
    
    /// Réinitialise uniquement les variables de tracking
    func resetTracking() {
        saveCalled = false
        retrieveCalled = false
        deleteCalled = false
        existsCalled = false
        
        saveCalledCount = 0
        retrieveCalledCount = 0
        deleteCalledCount = 0
        existsCalledCount = 0
        
        lastSavedData = nil
        lastSavedAccount = nil
        lastRetrievedAccount = nil
        lastDeletedAccount = nil
        lastExistsAccount = nil
    }
    
    /// Pré-charge le stockage avec des données
    func preloadStorage(with data: [String: String]) {
        storage = data
    }
}
