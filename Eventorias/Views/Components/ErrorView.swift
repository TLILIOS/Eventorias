import SwiftUI

struct ErrorView: View {
    let errorMessage: String
    var onRetry: () -> Void
    // Ajout du ViewModel comme paramètre
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
                
                ContentUnavailableView {
                    Circle()
                        .fill(Color(UIColor.systemGray5))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text("!")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        )
                } description: {
                    VStack(spacing: 8) {
                        Text("Error")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(errorMessage)
                            .font(.body)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                    }
                } actions: {
                    Button("Try again") {
                        onRetry()
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("Red"))
                    .cornerRadius(8)
                    .padding(.horizontal, 100)
                }
                .padding(.bottom, 130)
            }
        }
    }
}

// Preview mis à jour pour inclure un ViewModel factice
#Preview {
    // Création d'un EventViewModel factice pour l'aperçu
    let previewViewModel = AppDependencyContainer.shared.makeEventViewModel()
    
    ErrorView(
        errorMessage: "An error has occured,\nplease try again later", 
        onRetry: {}, 
        eventViewModel: previewViewModel
    )
    .preferredColorScheme(.dark)
}
