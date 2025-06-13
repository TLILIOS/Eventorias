//
//  EventsListContent.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 08/06/2025.
//

import SwiftUI

/// Vue pour afficher le contenu de la liste d'événements en fonction de différents états
/// Conforme au pattern MVVM en tant que Vue utilisant le ViewModel sans logique métier
struct EventsListContent: View {
    // MARK: - Properties
    let eventViewModel: EventViewModel
    
    // MARK: - Body
    var body: some View {
        contentView
    }
    
    // MARK: - Content Views
    @ViewBuilder
    private var contentView: some View {
        if eventViewModel.showingError {
            errorView
        } else if isEmptySearchResult {
            emptySearchResultView
        } else {
            EventScrollList(eventViewModel: eventViewModel)
        }
    }
    
    // MARK: - Computed Properties
    private var isEmptySearchResult: Bool {
        eventViewModel.filteredEvents.isEmpty && 
        !eventViewModel.isLoading && 
        !eventViewModel.searchText.isEmpty
    }
    
    // MARK: - Subviews
    private var errorView: some View {
        ErrorView(
            errorMessage: eventViewModel.errorMessage,
            onRetry: {
                Task {
                    await eventViewModel.fetchEvents()
                }
            },
            eventViewModel: eventViewModel
        )
    }
    
    private var emptySearchResultView: some View {
        VStack(spacing: 20) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("Aucun événement ne correspond à votre recherche")
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            Button("Effacer la recherche") {
                eventViewModel.searchText = ""
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 20)
            .background(Color("Red"))
            .cornerRadius(8)
        }
        .padding(40)
    }
}
