//
//  EventSearchBar.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 08/06/2025.
//
//
//  EventSearchBar.swift
//  Eventorias
//
import SwiftUI

struct EventSearchBar: View {
    let eventViewModel: EventViewModel
    @FocusState private var isSearchFocused: Bool
    
    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.white)
                    .padding(.leading, 12)
                
                TextField("", text: Binding(
                    get: { eventViewModel.searchText },
                    set: { eventViewModel.searchText = $0 }
                ))
                .placeholder(when: eventViewModel.searchText.isEmpty && !isSearchFocused) {
                    Text("Rechercher")
                        .foregroundColor(.gray.opacity(0.7))
                        .font(.system(size: 16))
                }
                .focused($isSearchFocused)
                .autocorrectionDisabled(true)
                .submitLabel(.search)
                .foregroundColor(.white)
                .font(.system(size: 16))
                
                if !eventViewModel.searchText.isEmpty {
                    Button {
                        eventViewModel.searchText = ""
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

// MARK: - Preview
#Preview {
    // Créer un EventViewModel factice pour l'aperçu
    let previewViewModel = AppDependencyContainer.shared.makeEventViewModel()
    previewViewModel.searchText = "" // Texte vide pour montrer le placeholder
    
    return ZStack {
        Color.black // Fond sombre pour mieux voir la barre de recherche
            .ignoresSafeArea()
        EventSearchBar(eventViewModel: previewViewModel)
    }
}
