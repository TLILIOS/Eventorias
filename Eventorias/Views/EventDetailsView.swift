//
//  EventDetailsView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI

struct EventDetailsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EventDetailsViewModel()
    let eventID: String
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Fond noir
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                // Vue de chargement
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            } else if let event = viewModel.event {
                // Contenu principal
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Image principale de l'événement
                        eventImageSection(event)
                        
                        // Informations de date et heure
                        dateTimeSection(event)
                        
                        // Description de l'événement
                        descriptionSection(event)
                        
                        // Adresse avec carte
                        locationSection(event)
                        
                        // Espacement en bas
                        Color.clear.frame(height: 30)
                    }
                }
                .scrollIndicators(.hidden)
            } else {
                // Vue d'erreur
                ContentUnavailableView {
                    Label("Événement non disponible", systemImage: "exclamationmark.triangle")
                } description: {
                    Text(viewModel.errorMessage.isEmpty ? "Impossible de charger les détails" : viewModel.errorMessage)
                } actions: {
                    Button("Réessayer") {
                        Task {
                            await viewModel.loadEvent(eventID: eventID)
                        }
                    }
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color("Red"))
                    .cornerRadius(8)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text(viewModel.event?.title ?? "Détails")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .alert("Erreur", isPresented: $viewModel.showingError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
        .task {
            await viewModel.loadEvent(eventID: eventID)
        }
        .onDisappear {
            viewModel.cancelTasks()
        }
    }
    
    // MARK: - Sections
    
    /// Section image de l'événement
    private func eventImageSection(_ event: Event) -> some View {
        ZStack(alignment: .bottom) {
            // Image de l'événement
            AsyncImage(url: URL(string: event.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(height: 280)
            .clipped()
            
            // Dégradé pour meilleure lisibilité
            LinearGradient(
                gradient: Gradient(colors: [Color.black.opacity(0.0), Color.black.opacity(0.5)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
        }
    }
    
    /// Section date et heure
    private func dateTimeSection(_ event: Event) -> some View {
        HStack(alignment: .center, spacing: 16) {
            // Date card
            VStack(alignment: .center) {
                Text(viewModel.formattedEventDay())
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                
                Text(viewModel.formattedEventMonth().uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(.top, -5)
                
                Text(String(Calendar.current.component(.year, from: event.date)))
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.white.opacity(0.8))
                    .padding(.top, -5)
            }
            .frame(width: 70, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color("DarkGry"))
            )
            .padding(.leading, 16)
            
            // Time
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.white)
                    
                    Text(viewModel.formattedEventTime())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            
            Spacer()
            
            // Organisateur
            AsyncImage(url: URL(string: event.organizerImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay {
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 48, height: 48)
            .clipShape(Circle())
            .padding(.trailing, 16)
        }
        .padding(.vertical, 16)
        .background(Color.black)
    }
    
    /// Section description
    private func descriptionSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Catégorie
            Text(event.category.uppercased())
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(viewModel.colorForCategory())
                )
                .padding(.leading, 16)
            
            // Description
            Text(event.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)
        }
    }
    
    /// Section localisation
    private func locationSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Address heading
            Text("Lieu")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.top, 8)
            
            // Address details
            Text(event.location)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.white.opacity(0.9))
                .lineSpacing(2)
                .padding(.horizontal, 16)
            
            // Map
            mapView(event)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
        }
        .padding(.top, 16)
    }
    
    /// Vue de la carte
    private func mapView(_ event: Event) -> some View {
        ZStack {
            if viewModel.isLoadingMap {
                Rectangle()
                    .fill(Color("DarkGry"))
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
            } else if let mapImageURL = viewModel.mapImageURL, viewModel.isMapAPIKeyConfigured {
                // Carte Google Maps Static
                AsyncImage(url: mapImageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color("DarkGry"))
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Rectangle()
                            .fill(Color("DarkGry"))
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "map")
                                        .font(.system(size: 32))
                                    Text("Impossible de charger la carte")
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 180)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Fallback map placeholder
                Rectangle()
                    .fill(Color("DarkGry"))
                    .frame(height: 180)
                    .cornerRadius(12)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "map")
                                .font(.system(size: 32))
                            
                            if !viewModel.isMapAPIKeyConfigured {
                                Text("Clé API Google Maps non configurée")
                                    .font(.caption)
                            } else {
                                Text("Impossible d'afficher la carte")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
            }
            
            // Pin de localisation
            if viewModel.coordinates != nil {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(Color("Red"))
                            .background(
                                Circle()
                                    .fill(.white)
                                    .frame(width: 22, height: 22)
                                    .blur(radius: 4)
                            )
                            .offset(y: -3)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        EventDetailsView(eventID: Event.sampleEvents.first?.id ?? "")
    }
}
