//
//  EventRowView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 02/06/2025.
//

import SwiftUI

struct EventRowView: View {
    let event: Event
    var backgroundColor: Color = Color("DarkGray")
    var body: some View {
        HStack(spacing: 12) {
            // Photo de profil circulaire
            CachedAsyncImage(url: URL(string: event.organizerImageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                case .failure:
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.gray)
                                .font(.system(size: 16))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            .padding(.leading, 10)
            // Contenu texte
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                Text(event.formattedDate)
                    .foregroundColor(.white)
                    .font(.system(size: 14))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Image de l'événement
            CachedAsyncImage(url: URL(string: event.imageURL ?? "")) { phase in
                switch phase {
                case .empty:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 136, height: 80) // largeur et hauteur fixes
                        .clipped()
                case .failure:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                                .font(.system(size: 20))
                        )
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 136, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 8))

        }
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

#Preview {
    EventRowView(event: Event.sampleEvents[0])
        .previewLayout(.sizeThatFits)
        .padding()
}
