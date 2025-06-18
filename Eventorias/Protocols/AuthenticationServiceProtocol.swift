//
//  AuthenticationServiceProtocol.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 17/06/2025.
//

import Foundation
import FirebaseAuth

protocol AuthenticationServiceProtocol {
    var currentUser: User? { get }
    var currentUserDisplayName: String { get }
    var currentUserEmail: String? { get }
}

// Implémentation réelle
class FirebaseAuthenticationService: AuthenticationServiceProtocol {
    var currentUser: User? {
        Auth.auth().currentUser
    }
    
    var currentUserDisplayName: String {
        Auth.auth().currentUser?.displayName ?? "Utilisateur anonyme"
    }
    
    var currentUserEmail: String? {
        Auth.auth().currentUser?.email
    }
}

// Mock pour les tests
class MockAuthenticationService: AuthenticationServiceProtocol {
    var currentUser: User? = nil
    var currentUserDisplayName: String = "Test User"
    var currentUserEmail: String? = "test@example.com"
    var shouldReturnNilUser: Bool = false
    
    init(userDisplayName: String = "Test User", userEmail: String = "test@example.com") {
        self.currentUserDisplayName = userDisplayName
        self.currentUserEmail = userEmail
    }
}
