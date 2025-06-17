// 
// AuthenticationViewModelProtocol.swift
// Eventorias
//
// Created on 13/06/2025.
//

import Foundation

/// Protocole définissant l'interface utilisée par ProfileViewModel pour interagir avec AuthenticationViewModel
protocol AuthenticationViewModelProtocol: AnyObject {
    // État d'authentification
    var isAuthenticated: Bool { get }
    
    // Méthode de déconnexion
    func signOut()
}

// Extension pour rendre AuthenticationViewModel conforme au protocole
extension AuthenticationViewModel: AuthenticationViewModelProtocol {}
