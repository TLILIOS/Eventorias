//
//  EventDetailsView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 05/06/2025.
//

import SwiftUI
import UIKit

struct EventDetailsView: View {
    // MARK: - Properties
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AppDependencyContainer.shared.makeEventDetailsViewModel()
    @State private var isSharePresented: Bool = false
    let eventID: String
    var backgroundColor: Color = Color("DarkGray")
    // MARK: - Body
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            } else if let event = viewModel.event {
                    VStack(alignment: .leading, spacing: 0) {
                        eventImageSection(event)
                        dateTimeSection(event)
                        descriptionSection(event)
                        
                        // Section invitations (si disponible)
                        if let invitationViewModel = viewModel.invitationViewModel {
                            Divider()
                                .background(Color.gray.opacity(0.3))
                                .padding(.vertical, 8)
                            
                            InvitationListView(
                                viewModel: invitationViewModel,
                                eventId: eventID,
                                isOrganizer: viewModel.isOrganizer
                            )
                            .padding(.vertical, 8)
                        }
                        
                        Spacer()
                        locationSection(event)
                    }
                    .background(Color.black)
              
            } else {
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
            
            ToolbarItem(placement: .navigationBarTrailing) {
                if let event = viewModel.event {
                    Button {
                        isSharePresented = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                    .sheet(isPresented: $isSharePresented) {
                        ShareSheet(event: event)
                    }
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
    

    private func eventImageSection(_ event: Event) -> some View {
        ZStack(alignment: .bottom) {
            CachedAsyncImage(url: URL(string: event.imageURL ?? "")) { phase in
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
        HStack(alignment: .top, spacing: 16) {
            // Section date et heure (côté gauche)
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .foregroundStyle(.white)
                        .frame(width: 20)
                    
                    Text(viewModel.formattedEventDate())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "clock")
                        .foregroundStyle(.white)
                        .frame(width: 20)
                    
                    Text(viewModel.formattedEventTime())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
            }
            .layoutPriority(1)
            
            Spacer(minLength: 8)
            
            // Image de profil de l'organisateur (côté droit)
            profileImage(event)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(Color.black)
    }
    
    /// Image de profil de l'organisateur
    private func profileImage(_ event: Event) -> some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.4))
                
            if let imageURL = URL(string: event.organizerImageURL ?? "") {
                CachedAsyncImage(url: imageURL) { phase in
                    switch phase {
                    case .empty:
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        Image(systemName: "person.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20))
                    @unknown default:
                        EmptyView()
                    }
                }
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            } else {
                Image(systemName: "person.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 20))
            }
        }
        .frame(width: 48, height: 48)
        .layoutPriority(0)
    }
    
    /// Section description
    private func descriptionSection(_ event: Event) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(event.description)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(.white)
                .lineSpacing(4)
                .multilineTextAlignment(.leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
        }
    }
    
   
   
    private func locationSection(_ event: Event) -> some View {
        HStack(alignment: .top, spacing: 12) {
            // Adresse à gauche
            VStack(alignment: .leading) {
                Text(event.location)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineSpacing(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            mapView(event)
                .frame(width: UIScreen.main.bounds.width * 0.45, height: 150)
                .cornerRadius(12)
                .clipped()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    
    /// Vue de la carte
    private func mapView(_ event: Event) -> some View {
        ZStack {
            if viewModel.isLoadingMap {
                // État de chargement
                Rectangle()
                    .fill(backgroundColor)
                    .frame(height: 200)
                    .overlay {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
            } else if let mapImageURL = viewModel.mapImageURL, viewModel.isMapAPIKeyConfigured {
                // Utiliser AsyncImage natif pour les cartes (plus compatible avec Google Maps)
                AsyncImage(url: mapImageURL) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(backgroundColor)
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
                            .fill(backgroundColor)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color("Red"))
                                    
                                    if !viewModel.errorMessage.isEmpty {
                                        Text(viewModel.errorMessage)
                                            .font(.caption)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 8)
                                            .fixedSize(horizontal: false, vertical: true)
                                    } else {
                                        Text("Erreur de chargement de la carte")
                                            .font(.caption)
                                    }
                                    
                                    Button(action: {
                                        Task {
                                            // Forcer le rechargement de la carte
                                            await viewModel.geocodeEventLocation()
                                        }
                                    }) {
                                        Label("Réessayer", systemImage: "arrow.counterclockwise")
                                            .font(.caption2)
                                            .padding(.vertical, 4)
                                            .padding(.horizontal, 8)
                                            .background(Color("Red").opacity(0.8))
                                            .foregroundColor(.white)
                                            .cornerRadius(4)
                                    }
                                    .padding(.top, 4)
                                }
                                .foregroundColor(.white.opacity(0.9))
                                .padding(12)
                            }
                    @unknown default:
                        EmptyView()
                    }
                }
                .clipped()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            } else {
                // Cas où la carte n'est pas disponible (URL null ou API non configurée)
                Rectangle()
                    .fill(backgroundColor)
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
                            
                            Button(action: {
                                Task {
                                    // Forcer le rechargement de la carte
                                    await viewModel.geocodeEventLocation()
                                }
                            }) {
                                Label("Réessayer", systemImage: "arrow.counterclockwise")
                                    .font(.caption2)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(Color("Red").opacity(0.8))
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                            }
                            .padding(.top, 8)
                        }
                        .foregroundColor(.white.opacity(0.7))
                    }
            }
            
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
        EventDetailsView(eventID: (Event.sampleEvents.indices.contains(2) ? Event.sampleEvents[2].id : "")!)
            .preferredColorScheme(.dark)
    }
}
