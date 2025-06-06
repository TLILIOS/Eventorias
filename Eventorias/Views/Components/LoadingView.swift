import SwiftUI

struct LoadingView: View {
    @State private var selectedTab: Tab = .events
    
    enum Tab {
        case events, profile
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.opacity(0.9).edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Search Bar
                ZStack {
                    Color(UIColor.systemGray6)
                        .cornerRadius(10)
                        .padding(.horizontal)
                    
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        Text("Search")
                            .foregroundColor(.gray)
                        Spacer()
                    }
                    .padding(.leading, 30)
                }
                .frame(height: 40)
                .padding(.top)
                
                // Sorting Button
                HStack {
                    Button {} label: {
                        HStack(spacing: 8) {
                            Image("Sorting")
                                .resizable()
                                .frame(width: 105, height: 35)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                // Loading Content
                Spacer()
                
                // Circular progress indicator
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2.0) 
                
                Spacer()
                
                // Custom Tab Bar
                HStack {
                    Spacer()
                    
                    // Events Tab
                    VStack {
                        Image(systemName: "calendar")
                            .foregroundColor(selectedTab == .events ? .red : .gray)
                        Text("Events")
                            .font(.caption)
                            .foregroundColor(selectedTab == .events ? .red : .gray)
                    }
                    .onTapGesture {
                        selectedTab = .events
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Profile Tab
                    VStack {
                        Image(systemName: "person")
                            .foregroundColor(selectedTab == .profile ? .red : .gray)
                        Text("Profile")
                            .font(.caption)
                            .foregroundColor(selectedTab == .profile ? .red : .gray)
                    }
                    .onTapGesture {
                        selectedTab = .profile
                    }
                    .frame(maxWidth: .infinity)
                    
                    Spacer()
                }
                .padding(.top, 10)
                .padding(.bottom, 5)
                .background(Color.black.opacity(0.9))
                .edgesIgnoringSafeArea(.bottom)
            }
        }
    }
}

// Preview pour visualiser le composant
struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
            .preferredColorScheme(.dark)
    }
}
