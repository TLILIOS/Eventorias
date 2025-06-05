//
//  EventoriasApp.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 26/05/2025.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct EventoriasApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AuthenticationViewModel()
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authViewModel.isAuthenticated {
                    EventList()
                        .environmentObject(authViewModel)
                } else {
                    SignInView()
                        .environmentObject(authViewModel)
                }
            }
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    // Déconnexion automatique quand l'application passe en arrière-plan
                    // Utilise la méthode qui conserve les identifiants pour les pré-remplir
                    authViewModel.signOutWithoutClearingForm()
                }
            }
        }
    }
}
