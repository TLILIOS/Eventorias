//
//  FirebaseAdapters.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 19/06/2025.
//

import Foundation
import FirebaseAuth

// Utilisation des protocols définis dans AuthProviderProtocol.swift

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
    
    // Note: cette méthode n'est pas définie dans le protocole UserProtocol de AuthProviderProtocol.swift
    // mais est utilisée dans l'implémentation actuelle
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
    
    var additionalUserInfo: [String: Any]? {
        return firebaseAuthDataResult.additionalUserInfo?.dictionaryValue
    }
}

// MARK: - User Extension

/// Extension pour convertir User de Firebase en UserProtocol
extension User: UserProtocol {
    /// Implémentation de getPhotoURL() exigée par UserProtocol
    public func getPhotoURL() -> URL? {
        return photoURL
    }
}
