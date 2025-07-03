//
//  EventSortButton.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 08/06/2025.
//
//
//  EventSortButton.swift
//  Eventorias
//
import SwiftUI

struct EventSortButton: View {
    let eventViewModel: EventViewModel
    @State private var isShowingSortOptions = false
    @State private var isShowingCategoryFilter = false
    @State private var isShowingDateFilter = false
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(60*60*24*30) // +30 jours par défaut
    
    var body: some View {
        HStack {
            Button {
                isShowingSortOptions = true
            } label: {
                Image("Sorting")
                    .resizable()
                    .frame(width: 105, height: 35)
            }
            
            Spacer()
            
            // Affichage du mode de vue sélectionné
            Text(eventViewModel.viewMode == .list ? "Liste" : "Calendrier")
                .foregroundColor(.white)
                .font(.caption)
                .padding(.trailing, 5)
            
            // Bouton pour changer de mode d'affichage
            Button {
                eventViewModel.toggleViewMode()
            } label: {
                Image(systemName: eventViewModel.viewMode == .list ? "calendar" : "list.bullet")
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color.gray.opacity(0.4))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        // Menu de tri
        .confirmationDialog(
            "Trier et filtrer",
            isPresented: $isShowingSortOptions,
            titleVisibility: .visible
        ) {
            // Options de tri
            Section {
                ForEach(EventViewModel.SortOption.allCases) { option in
                    Button(option.rawValue) {
                        Task {
                            await eventViewModel.updateSortOption(option)
                        }
                    }
                }
            }
            
            // Options de filtrage
            Button("Filtrer par catégorie") {
                isShowingCategoryFilter = true
            }
            
            Button("Filtrer par date") {
                isShowingDateFilter = true
            }
            
            // Réinitialiser les filtres
            if eventViewModel.hasActiveFilters {
                Button("Réinitialiser tous les filtres", role: .destructive) {
                    eventViewModel.resetAllFilters()
                }
            }
            
            Button("Annuler", role: .cancel) {}
        }
        // Menu de sélection de catégorie
        .sheet(isPresented: $isShowingCategoryFilter) {
            NavigationStack {
                List {
                    Section {
                        Button("Toutes les catégories") {
                            eventViewModel.selectedCategory = nil
                            isShowingCategoryFilter = false
                        }
                        
                        ForEach(EventCategory.allCases) { category in
                            Button {
                                eventViewModel.selectedCategory = category
                                isShowingCategoryFilter = false
                            } label: {
                                HStack {
                                    Label(
                                        category.rawValue,
                                        systemImage: category.icon
                                    )
                                    .foregroundColor(category.color)
                                    
                                    Spacer()
                                    
                                    if eventViewModel.selectedCategory == category {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    } header: {
                        Text("Sélectionner une catégorie")
                    }
                }
                .navigationTitle("Filtrer par catégorie")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") {
                            isShowingCategoryFilter = false
                        }
                    }
                }
            }
            .presentationDetents([.medium])
            .preferredColorScheme(.dark)
        }
        // Menu de sélection de période
        .sheet(isPresented: $isShowingDateFilter) {
            NavigationStack {
                Form {
                    Section("Période") {
                        DatePicker("Date de début", selection: $startDate, displayedComponents: .date)
                        DatePicker("Date de fin", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                    
                    Section {
                        Button("Appliquer") {
                            eventViewModel.dateRange = (startDate, endDate)
                            isShowingDateFilter = false
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                        .foregroundColor(.blue)
                        
                        if eventViewModel.hasDateFilter {
                            Button("Réinitialiser") {
                                eventViewModel.dateRange = nil
                                isShowingDateFilter = false
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.red)
                        }
                    }
                }
                .navigationTitle("Filtrer par date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Annuler") {
                            isShowingDateFilter = false
                        }
                    }
                }
            }
            .presentationDetents([.height(350)])
            .preferredColorScheme(.dark)
        }
    }
}
