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
                // Utilisation de GeometryReader pour contraindre strictement la largeur
                GeometryReader { geo in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Contenu dans un cadre avec largeur exacte
                            VStack(alignment: .leading, spacing: 0) {
                                // Image principale de l'événement
                                eventImageSection(event)
                                
                                // Informations de date et heure
                                dateTimeSection(event)
                                
                                // Description de l'événement
                                descriptionSection(event)
                                
                                // Adresse avec carte
                                locationSection(event)
                            }
                            .frame(width: geo.size.width) // Force la largeur exacte de l'écran
                            .background(Color.black)
                            .overlay(
                                Rectangle()
                                    .strokeBorder(Color.gray.opacity(0.5), lineWidth: 1)
                            )
                        
                            // Espacement en bas
                            Color.clear.frame(height: 16)
                        }
                    }
                    .frame(width: geo.size.width) // Contraindre la ScrollView également
                    .scrollIndicators(.hidden)
                }
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
        VStack(alignment: .leading, spacing: 16) {
            // Date avec icône calendrier
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(.white)
                    .frame(width: 20)
                
                Text(viewModel.formattedEventDate())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Heure avec icône horloge
            HStack(spacing: 8) {
                Image(systemName: "clock")
                    .foregroundStyle(.white)
                    .frame(width: 20)
                
                Text(viewModel.formattedEventTime())
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Organisateur - placé en bas
            HStack {
                Spacer()
                
                AsyncImage(url: URL(string: event.organizerImageURL ?? "")) { phase in
                    switch phase {
                    case .empty:
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .overlay {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            }
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    case .failure:
                        Circle()
                            .fill(Color.black.opacity(0.4))
                            .overlay {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
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
                .lineLimit(1) // Limiter à une seule ligne
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
                .fixedSize(horizontal: false, vertical: true) // Fix pour éviter le débordement horizontal
                .frame(maxWidth: .infinity, alignment: .leading) // Contrainte de largeur stricte
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
            
            // Address and Map - side by side
            HStack(alignment: .top, spacing: 12) {
                // Address details
                VStack(alignment: .leading) {
                    Text(event.location)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.white.opacity(0.9))
                        .lineSpacing(2) 
                        .lineLimit(nil) // Autoriser plusieurs lignes
                        .fixedSize(horizontal: false, vertical: true) // Fix pour éviter le débordement horizontal
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 8)
                }
                .frame(width: UIScreen.main.bounds.width * 0.4)
                .padding(.leading, 16)
                
                // Map
                mapView(event)
                    .frame(width: UIScreen.main.bounds.width * 0.45)
                    .cornerRadius(12)
                    .clipped()
                    .padding(.trailing, 16)
            }
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
                    .frame(height: 150)
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
                                        .font(.system(size: 24))
                                    Text("Erreur carte")
                                        .font(.caption)
                                }
                                .foregroundColor(.white.opacity(0.7))
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(height: 150)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Fallback map placeholder
                Rectangle()
                    .fill(Color("DarkGry"))
                    .frame(height: 150)
                    .cornerRadius(8)
                    .overlay {
                        VStack(spacing: 6) {
                            Image(systemName: "map")
                                .font(.system(size: 24))
                            
                            if !viewModel.isMapAPIKeyConfigured {
                                Text("API non configurée")
                                    .font(.caption2)
                            } else {
                                Text("Carte indisponible")
                                    .font(.caption2)
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
