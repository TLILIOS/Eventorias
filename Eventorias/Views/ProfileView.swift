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
    @StateObject private var profileViewModel: ProfileViewModel
    @State private var notificationsEnabled = true
    @State private var showingSignOutAlert = false
    @Binding var selectedTab: Int
    
    init(selectedTab: Binding<Int>) {
        self._selectedTab = selectedTab
        // Utiliser le container de dépendances pour créer le ViewModel
        // La vraie instance avec l'authViewModel sera injectée dans onAppear
        let container = AppDependencyContainer.shared
        self._profileViewModel = StateObject(wrappedValue: container.makeProfileViewModel())
    }
    
    func signOut() {
        showingSignOutAlert = false
        authViewModel.signOut() // Utiliser directement authViewModel pour la déconnexion
        selectedTab = 1
    }
    
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
                        if let avatarUrl = profileViewModel.avatarUrl {
                            AsyncImage(url: avatarUrl) { phase in
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
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                )
                                .frame(width: 50, height: 50)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // Champs de profil
                    VStack(spacing: 25) {
                        // Champ Name
                        Text(profileViewModel.displayName)
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
                        Text(profileViewModel.email)
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
                    
                    // Bouton de déconnexion
                    Button(action: {
                        showingSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Déconnexion")
                                .foregroundColor(.red)
                                .font(.system(size: 16, weight: .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color("DarkGry"))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Utiliser le container de dépendances pour créer le ViewModel
                let container = AppDependencyContainer.shared
                
                // Configurer le ProfileViewModel avec l'authViewModel injecté
                profileViewModel.updateAuthenticationViewModel(authViewModel)
                
                // Forcer le rechargement des données du profil
                profileViewModel.loadUserProfile()
            }
            .alert("Déconnexion", isPresented: $showingSignOutAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Déconnexion", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir vous déconnecter ?")
            }
        }
    }
}

#Preview {
    ProfileView(selectedTab: .constant(1))
        .environmentObject(AppDependencyContainer.shared.makeAuthenticationViewModel())
}
