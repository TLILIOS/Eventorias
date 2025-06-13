import SwiftUI

struct LoadingView: View {
    // Ajout d'un paramètre pour le viewModel
    let eventViewModel: EventViewModel
    @State private var selectedTab: Tab = .events
    
    enum Tab {
        case events, profile
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Utilisation du composant EventSearchBar existant
                EventSearchBar(eventViewModel: eventViewModel)
                
                // Utilisation du composant EventSortButton existant
                EventSortButton(eventViewModel: eventViewModel)
                
                // Loading Content
                Spacer()
                
                // Circular progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0) 
                
                Spacer()
            }
        }
    }
}

// Preview mis à jour pour passer un viewModel factice
#Preview {
    // Création d'un EventViewModel factice pour l'aperçu
    let previewViewModel = EventViewModel()
    
    return LoadingView(eventViewModel: previewViewModel)
        .preferredColorScheme(.dark)
}
