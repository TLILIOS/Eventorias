// 
// MockAuthViewModel.swift
// EventoriasTests
//
// Created on 13/06/2025.
//

import Foundation
import SwiftUI
@testable import Eventorias

class MockAuthViewModel: ObservableObject, AuthenticationViewModelProtocol {
    // Published properties pour simuler AuthenticationViewModel
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var showingError = false
    @Published var email = ""
    @Published var password = ""
    @Published var username = ""
    
    // Tracking properties pour les tests
    var signInCalled = false
    var signUpCalled = false
    var signOutCalled = false
    var dismissErrorCalled = false
    
    // Mock responses
    var shouldSucceed = true
    var mockError: Error?
    
    // Méthodes du protocole
    func signOut() {
        signOutCalled = true
        isAuthenticated = false
    }
    
    // Méthodes additionnelles pour les tests
    func signIn() async {
        signInCalled = true
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldSucceed {
            isAuthenticated = true
        } else {
            showingError = true
            errorMessage = mockError?.localizedDescription ?? "Mock error occurred"
        }
        
        isLoading = false
    }
    
    func signUp() async {
        signUpCalled = true
        isLoading = true
        
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        if shouldSucceed {
            isAuthenticated = true
        } else {
            showingError = true
            errorMessage = mockError?.localizedDescription ?? "Mock error occurred"
        }
        
        isLoading = false
    }
    
    func dismissError() {
        dismissErrorCalled = true
        showingError = false
        errorMessage = ""
    }
    

}
