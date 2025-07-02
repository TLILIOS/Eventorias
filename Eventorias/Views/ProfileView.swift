//
// ProfileView.swift
// Eventorias
//
// Created by TLiLi Hamdi on 02/06/2025.
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
        Task {
            await authViewModel.signOut() // Utiliser directement authViewModel pour la déconnexion
            selectedTab = 1
        }
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
                            .accessibilityHeading(.h1)
                        
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
                            .accessibilityLabel("Photo de profil de \(profileViewModel.displayName)")
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .overlay(
                                    Image(systemName: "person.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 20))
                                )
                                .frame(width: 50, height: 50)
                                .accessibilityLabel("Photo de profil par défaut")
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    
                    // Champs de profil
                    VStack(spacing: 25) {
                        // Champ Name avec label
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nom d'utilisateur")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            StyledTextField(
                                placeholder: "Nom d'utilisateur",
                                text: .constant(profileViewModel.displayName),
                                isDisabled: true,
                                accessibilityId: "userNameField",
                                accessibilityLabel: "Nom d'utilisateur",
                                accessibilityHint: "Champ en lecture seule"
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // Champ E-mail avec label
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Adresse e-mail")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            StyledTextField(
                                placeholder: "Adresse e-mail",
                                text: .constant(profileViewModel.email),
                                keyboardType: .emailAddress,
                                textContentType: .emailAddress,
                                isDisabled: true,
                                accessibilityId: "emailField",
                                accessibilityLabel: "Adresse e-mail",
                                accessibilityHint: "Champ en lecture seule"
                            )
                            .padding(.horizontal, 16)
                        }
                        
                        // Switch Notifications avec label
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Préférences")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.leading, 16)
                            
                            HStack {
                                Toggle("Notifications", isOn: $notificationsEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .red))
                                    .accessibilityLabel("Activer les notifications")
                                    .accessibilityValue(notificationsEnabled ? "Activé" : "Désactivé")
                                
                                Text("Notifications")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .frame(height: 56)
                            .background(Color("DarkGray"))
                            .cornerRadius(12)
                            .padding(.horizontal, 16)
                        }
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
                        .background(Color("DarkGray"))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                    .accessibilityLabel("Se déconnecter")
                    .accessibilityHint("Ouvre une alerte de confirmation")
                }
            }
            .navigationBarHidden(true)
            .accessibilityElement(children: .contain)
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
