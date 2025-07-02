import Foundation
@testable import Eventorias

/// Mock pour KeychainServiceProtocol permettant de tester les fonctionnalités dépendant
/// du Keychain sans interagir avec le vrai Keychain système
final class MockKeychainService: KeychainServiceProtocol {
    /// Le service associé à ce mock
    let service: String = "com.eventorias.mock"
    
    /// Stockage en mémoire pour simuler le Keychain
    private var inMemoryStorage: [String: String] = [:]
    
    /// Variables pour suivre les appels aux méthodes (utile pour vérifier dans les tests)
    var saveCalled = false
    var saveCallCount = 0
    var updateCalled = false
    var retrieveCalled = false
    var retrieveCallCount = 0
    var deleteCalled = false
    var deleteCallCount = 0
    var existsCalled = false
    
    /// Variables pour stocker les données sauvegardées pour vérification
    var savedValues: [String: String] = [:]
    var retrieveResults: [String: String] = [:]
    
    /// Variables pour contrôler le comportement simulé
    var shouldThrowError = false
    var shouldThrowOnSave = false
    var shouldThrowOnRetrieve = false
    var mockError: KeychainError = .unexpectedError("Erreur simulée pour les tests")
    var saveError: KeychainError = .unexpectedError("Erreur de sauvegarde simulée pour les tests")
    
    /// Sauvegarde une donnée en mémoire (simule le Keychain)
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Throws: KeychainError en cas d'échec simulé
    func save(_ data: String, for account: String) throws {
        saveCalled = true
        saveCallCount += 1
        
        if shouldThrowError || shouldThrowOnSave {
            throw shouldThrowOnSave ? saveError : mockError
        }
        
        if exists(for: account) {
            throw KeychainError.unexpectedError("L'élément existe déjà, utilisez update()")
        }
        
        inMemoryStorage[account] = data
        savedValues[account] = data
    }
    
    /// Met à jour une donnée en mémoire ou la crée si elle n'existe pas
    /// - Parameters:
    ///   - data: La chaîne de caractères à sauvegarder
    ///   - account: L'identifiant du compte/clé
    /// - Throws: KeychainError en cas d'échec simulé
    func update(_ data: String, for account: String) throws {
        updateCalled = true
        
        if shouldThrowError {
            throw mockError
        }
        
        inMemoryStorage[account] = data
    }
    
    /// Récupère une donnée depuis le stockage en mémoire
    /// - Parameter account: L'identifiant du compte/clé
    /// - Returns: La donnée stockée
    /// - Throws: KeychainError si non trouvée ou erreur simulée
    func retrieve(for account: String) throws -> String {
        retrieveCalled = true
        retrieveCallCount += 1
        
        if shouldThrowError || shouldThrowOnRetrieve {
            throw mockError
        }
        
        if let predefinedValue = retrieveResults[account] {
            return predefinedValue
        }
        
        guard let value = inMemoryStorage[account] else {
            throw KeychainError.itemNotFound
        }
        
        return value
    }
    
    /// Supprime une donnée du stockage en mémoire
    /// - Parameter account: L'identifiant du compte/clé à supprimer
    /// - Throws: KeychainError en cas d'échec simulé
    func delete(for account: String) throws {
        deleteCalled = true
        deleteCallCount += 1
        
        if shouldThrowError {
            throw mockError
        }
        
        guard inMemoryStorage[account] != nil else {
            throw KeychainError.itemNotFound
        }
        
        inMemoryStorage.removeValue(forKey: account)
        savedValues.removeValue(forKey: account)
    }
    
    /// Vérifie si une donnée existe dans le stockage en mémoire
    /// - Parameter account: L'identifiant du compte/clé à vérifier
    /// - Returns: true si la donnée existe, false sinon
    func exists(for account: String) -> Bool {
        existsCalled = true
        return inMemoryStorage[account] != nil
    }
    
    /// Réinitialise l'état du mock pour les tests
    func reset() {
        inMemoryStorage.removeAll()
        saveCalled = false
        updateCalled = false
        retrieveCalled = false
        deleteCalled = false
        existsCalled = false
        shouldThrowError = false
    }
}
