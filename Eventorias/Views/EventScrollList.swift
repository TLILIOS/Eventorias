//
//  EventScrollList.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 10/06/2025.
//

import SwiftUI

struct EventScrollList: View {
    let eventViewModel: EventViewModel
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(eventViewModel.filteredEvents) { event in
                    NavigationLink(destination:
                        EventDetailsView(eventID: event.id ?? "")
                            .toolbar(.hidden, for: .tabBar)
                    ) {
                        EventRowView(event: event)
                            .padding(.horizontal, 16)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
        .refreshable {
            Task {
                await eventViewModel.refreshEvents()
            }
        }
    }
}

#Preview {
    EventScrollList(eventViewModel: EventViewModel())
        .preferredColorScheme(.dark)
}
