//
//  EventList.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 27/05/2025.
//
import SwiftUI

struct EventList: View {
    // MARK: - Properties
    @FocusState private var isSearchFocused: Bool
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @StateObject private var eventViewModel = EventViewModel()
    @State private var isShowingSortOptions = false
    @State private var searchText = ""
    @State private var selectedTab = 0
    @State private var showingEventCreation = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Afficher la vue en fonction de l'onglet sélectionné
            if selectedTab == 0 {
                NavigationStack {
                ZStack {
                    Color.black.edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 0) {
                        // Barre de recherche
                        searchBar
                        
                        // Bouton de tri
                        sortingButton
                        
                        // Liste des événements
                        eventsList
                    }
                    .overlay {
                        if eventViewModel.isLoading {
                            ProgressView("Chargement...")
                                .progressViewStyle(.circular)
                                .background(Color(UIColor.systemBackground).opacity(0.7))
                        }
                    }
                    .overlay {
                        if eventViewModel.filteredEvents.isEmpty && !eventViewModel.isLoading {
                            ContentUnavailableView {
                                Label("Aucun événement", systemImage: "calendar.badge.exclamationmark")
                            } description: {
                                if !searchText.isEmpty {
                                    Text("Aucun résultat pour \"\(searchText)\"")
                                } else {
                                    Text("Aucun événement disponible")
                                }
                            }
                        }
                    }
                }
                .navigationBarHidden(true)
                .confirmationDialog("Trier par", isPresented: $isShowingSortOptions, titleVisibility: .visible) {
                    ForEach(EventViewModel.SortOption.allCases) { option in
                        Button(option.rawValue) {
                            eventViewModel.sortOption = option
                        }
                    }
                    Button("Annuler", role: .cancel) {}
                }
                .alert("Erreur", isPresented: $eventViewModel.showingError) {
                    Button("OK") { eventViewModel.dismissError() }
                } message: {
                    Text(eventViewModel.errorMessage)
                }
                .navigationDestination(isPresented: $showingEventCreation) {
                    EventCreationView(eventViewModel: eventViewModel)
                }
            }
            } else if selectedTab == 1 {
                ProfileView(selectedTab: $selectedTab)
                    .environmentObject(authViewModel)
            }
            
            // Bouton flottant et TabBar
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    // Bouton d'ajout flottant (visible uniquement dans l'onglet Events)
                    if selectedTab == 0 {
                        Button {
                            showingEventCreation = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.red)
                                .cornerRadius(20)
                                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        }
                        .offset(y: -30)
                        .padding(.trailing, 20)
                    }
                }
                TabBar(selectedTab: $selectedTab)
            }
        }
        .onAppear {
            Task {
                await eventViewModel.fetchEvents()
            }
        }
        .onChange(of: searchText) { newValue in
            eventViewModel.searchText = newValue
        }
    }
    
    // MARK: - Subviews
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                
                TextField("", text: $searchText)
                    .placeholder(when: searchText.isEmpty && !isSearchFocused) {
                        Text("Rechercher")
                            .foregroundColor(.gray.opacity(0.7))
                            .font(.system(size: 16))
                    }
                    .focused($isSearchFocused)
                    .autocorrectionDisabled(true)
                    .submitLabel(.search)
                    .foregroundColor(.white) 
                    .font(.system(size: 16))
                    .onChange(of: searchText) { _, _ in
                        // Force le rafraîchissement de la vue
                        eventViewModel.objectWillChange.send()
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .padding(.trailing, 12)
                    }
                }
            }
            .frame(height: 45)
            .background(Color("DarkGry"))
            .cornerRadius(22.5)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }
    
    private var sortingButton: some View {
        HStack {
            Button {
                isShowingSortOptions = true
            } label: {
                HStack(spacing: 8) {
                    Image("Sorting")
                        .resizable()
                        .frame(width: 105 , height: 35)
                }
            }
     
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    private var eventsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(eventViewModel.filteredEvents) { event in
                    EventRowView(event: event)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100) // Nécessaire pour l'espace au-dessus de la TabBar
        }
        .refreshable {
            Task {
                await eventViewModel.fetchEvents()
            }
        }
    }
}

// MARK: - Extension pour le placeholder
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - TabBar
struct TabBar: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack {
            Spacer()
            
            // Tab Events
            VStack(spacing: 4) {
                Image(systemName: "calendar")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 0 ? .red : .white)
                Text("Events")
                    .font(.caption)
                    .foregroundColor(selectedTab == 0 ? .red : .white)
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                withAnimation {
                    selectedTab = 0
                }
            }
            
            // Espace pour le bouton flottant
            Spacer()
                .frame(width: 80)
            
            // Tab Profile
            VStack(spacing: 4) {
                Image(systemName: "person")
                    .font(.system(size: 24))
                    .foregroundColor(selectedTab == 1 ? .red : .white)
                Text("Profile")
                    .font(.caption)
                    .foregroundColor(selectedTab == 1 ? .red : .white)
            }
            .frame(maxWidth: .infinity)
            .onTapGesture {
                withAnimation {
                    selectedTab = 1
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 12)
        .background(Color.black)
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color.gray.opacity(0.3)),
            alignment: .top
        )
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        EventList()
            .environmentObject(AuthenticationViewModel())
    }
}
