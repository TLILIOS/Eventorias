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
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .confirmationDialog(
            "Trier par",
            isPresented: $isShowingSortOptions,
            titleVisibility: .visible
        ) {
            ForEach(EventViewModel.SortOption.allCases) { option in
                Button(option.rawValue) {
                    Task {
                        await eventViewModel.updateSortOption(option)
                    }
                }
            }
            Button("Annuler", role: .cancel) {}
        }
    }
}
