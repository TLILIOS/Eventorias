//
//  ProfileView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 02/06/2025.
//
import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject private var authViewModel: AuthenticationViewModel
    @State private var notificationsEnabled = true
    @State private var showingSignOutAlert = false
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // Header avec titre et avatar
                    HStack {
                        Text("User profile")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        // Avatar circulaire
                        AsyncImage(url: URL(string: "https://example.com/avatar.jpg")) { phase in
                            switch phase {
                            case .empty:
                                Circle()
                                    .fill(Color.gray.opacity(0.3))
                                    .overlay(
                                        Image(systemName: "person.fill")
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
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
                                            .foregroundColor(.white)
                                            .font(.system(size: 20))
                                    )
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // Champs de profil
                    VStack(spacing: 25) {
                        // Champ Name
                        Text(Auth.auth().currentUser?.displayName ?? "Hamdi")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 56)
                                .background(Color("DarkGry"))
                                .cornerRadius(12)
                        
                        .padding(.horizontal, 16)
                        
                        // Champ E-mail
                            Text(Auth.auth().currentUser?.email ?? "hamdi@yahoo.fr")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(height: 56)
                                .background(Color("DarkGry"))
                                .cornerRadius(10)
                                .padding(.horizontal, 16)
                        
                        // Switch Notifications
                        HStack {
                            Toggle("", isOn: $notificationsEnabled)
                                .labelsHidden()
                                .toggleStyle(SwitchToggleStyle(tint: .red))
                            
                            Text("Notifications")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                    }
                    .padding(.top, 30)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ProfileView(selectedTab: .constant(1))
        .environmentObject(AuthenticationViewModel())
}
