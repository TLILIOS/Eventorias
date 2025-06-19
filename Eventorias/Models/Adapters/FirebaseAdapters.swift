//
//  FirebaseAdapters.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseAuth

// MARK: - User Protocol

/// Protocole définissant un utilisateur authentifié
public protocol UserProtocol {
    /// L'identifiant unique de l'utilisateur
    var uid: String { get }
    
    /// L'adresse e-mail de l'utilisateur (si disponible)
    var email: String? { get }
    
    /// Le nom d'affichage de l'utilisateur (si disponible)
    var displayName: String? { get }
    
    /// L'URL de la photo de profil de l'utilisateur (si disponible)
    var photoURL: URL? { get }
    
    /// Indique si l'utilisateur est anonyme
    var isAnonymous: Bool { get }
    
    /// Indique si l'adresse e-mail de l'utilisateur est vérifiée
    var isEmailVerified: Bool { get }
    
    /// Méthode pour obtenir l'URL de la photo de profil (contourne les limitations des protocoles existentiels)
    func getPhotoURL() -> URL?
}

// MARK: - AuthDataResult Protocol

/// Protocole définissant le résultat d'une opération d'authentification
public protocol AuthDataResultProtocol {
    /// L'utilisateur authentifié
    var user: UserProtocol { get }
}

// MARK: - Firebase User Adapter

/// Adaptateur pour le type User de Firebase
final class FirebaseUserAdapter: UserProtocol {
    private let firebaseUser: User
    
    init(_ firebaseUser: User) {
        self.firebaseUser = firebaseUser
    }
    
    var uid: String {
        return firebaseUser.uid
    }
    
    var email: String? {
        return firebaseUser.email
    }
    
    var displayName: String? {
        return firebaseUser.displayName
    }
    
    var photoURL: URL? {
        return firebaseUser.photoURL
    }
    
    var isAnonymous: Bool {
        return firebaseUser.isAnonymous
    }
    
    var isEmailVerified: Bool {
        return firebaseUser.isEmailVerified
    }
    
    func getPhotoURL() -> URL? {
        return firebaseUser.photoURL
    }
}

// MARK: - Firebase AuthDataResult Adapter

/// Adaptateur pour le type AuthDataResult de Firebase
final class FirebaseAuthDataResultAdapter: AuthDataResultProtocol {
    private let firebaseAuthDataResult: AuthDataResult
    
    init(_ firebaseAuthDataResult: AuthDataResult) {
        self.firebaseAuthDataResult = firebaseAuthDataResult
    }
    
    var user: UserProtocol {
        return FirebaseUserAdapter(firebaseAuthDataResult.user)
    }
}

// MARK: - User Extension

/// Extension pour convertir User de Firebase en UserProtocol
extension User: UserProtocol {
    /// Retourne l'URL de la photo de profil
    public func getPhotoURL() -> URL? {
        return photoURL
    }
}
