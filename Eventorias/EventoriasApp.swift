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
        // Ne pas initialiser Firebase pendant les tests UI
        let isUITesting = ProcessInfo.processInfo.arguments.contains("UI_TESTING")
        if !isUITesting {
            FirebaseApp.configure()
        } else {
            print("Firebase non initialisé car en mode test UI")
        }
        return true
    }
}

@main
struct EventoriasApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authViewModel = AppDependencyContainer.shared.makeAuthenticationViewModel()
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
        }
    }
}
