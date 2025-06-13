
//  EventList.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//
import SwiftUI

struct EventList: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State private var eventViewModel = EventViewModel()
    
    var body: some View {
        TabView {
            EventsTabView(eventViewModel: eventViewModel)
                .tabItem {
                    Image(systemName: "calendar")
                    Text("Events")
                }
                .tag(0)
            
            ProfileView(selectedTab: .constant(1))
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person")
                    Text("Profile")
                }
                .tag(1)
        }
        .toolbarBackground(Color.black, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .accentColor(.red)
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.black
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.white
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.white]
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
            
            Task {
                await eventViewModel.fetchEvents()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    EventList()
        .environmentObject(AuthenticationViewModel())
        .preferredColorScheme(.dark)
}
