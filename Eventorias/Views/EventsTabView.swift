//
//  EventsTabView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 08/06/2025.
//
//
//  EventsTabView.swift
//  Eventorias
//
import SwiftUI

struct EventsTabView: View {
    let eventViewModel: EventViewModel
    @State private var showingEventCreation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond de base
                Color.black.edgesIgnoringSafeArea(.all)
                
                // Gestion des différents états d'affichage
                if eventViewModel.isLoading {
                    // Afficher LoadingView pendant le chargement
                    LoadingView(eventViewModel: eventViewModel)
                        .transition(.opacity)
                } else if eventViewModel.showingError {
                    // Afficher l'erreur si présente
                    ErrorView(
                        errorMessage: eventViewModel.errorMessage,
                        onRetry: {
                            eventViewModel.dismissError()
                            Task {
                                await eventViewModel.fetchEvents()
                            }
                        },
                        eventViewModel: eventViewModel
                    )
                    .transition(.opacity)
                } else {
                    // Afficher le contenu principal seulement si pas en chargement et pas d'erreur
                    EventsMainContent(eventViewModel: eventViewModel)
                        .transition(.opacity)
                }
                
                // Bouton flottant toujours visible
                FloatingActionButton {
                    showingEventCreation = true
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showingEventCreation) {
                EventCreationView(eventViewModel: eventViewModel)
                    .toolbar(.hidden, for: .tabBar)
            }
        }
    }
}

// MARK: - Events Main Content
struct EventsMainContent: View {
    let eventViewModel: EventViewModel
    
    var body: some View {
        Color.black.edgesIgnoringSafeArea(.all)
            .overlay {
                VStack(spacing: 0) {
                    EventSearchBar(eventViewModel: eventViewModel)
                    EventSortButton(eventViewModel: eventViewModel)
                    
                    // Affichage conditionnel en fonction du mode choisi
                    if eventViewModel.viewMode == .list {
                        EventsListContent(eventViewModel: eventViewModel)
                    } else {
                        EventCalendarView(eventViewModel: eventViewModel)
                    }
                }
            }
    }
}
