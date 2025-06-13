//
//  EventCreationView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 04/06/2025.
//


import SwiftUI
import PhotosUI
import Combine

// Types d'alertes de permissions
enum PermissionAlertType {
    case camera
    case photoLibrary
}
@MainActor
struct EventCreationView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: EventCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Image picker state
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showImageSourceOptions = false
    @State private var showingPermissionAlert = false
    @State private var permissionAlertType = PermissionAlertType.camera
    
    // Form values
    @State private var title = ""
    @State private var description = ""
    @State private var date = Date()
    @State private var address = ""
    @State private var selectedImage: UIImage?
    
    // UI state
    @State private var showingAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    // MARK: - Initialization
    
    init(eventViewModel: EventViewModel) {
        _viewModel = StateObject(wrappedValue: EventCreationViewModel(eventViewModel: eventViewModel))
    }
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background color
            Color.black
                .edgesIgnoringSafeArea(.all)
            
            // Main content
            VStack(spacing: 0) {
                // Header
                header
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Form fields
                        formFields
                        
                        // Image selection buttons
                        imageButtons
                        
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal)
                }
                
                // Validate button
                validateButton
            }
        }
        .navigationTitle("Creation of an event")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .alert(alertTitle, isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .alert(isPresented: $showingPermissionAlert) {
            getPermissionAlert(type: permissionAlertType)
        }
        .sheet(isPresented: $showImagePicker) {
            PHPickerView(image: $selectedImage)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: selectedImage) { newImage in
            print("⚠️ DEBUG: selectedImage changée - image présente: \(newImage != nil)")
            viewModel.eventImage = newImage
        }
        .onAppear {
            // Initialiser les valeurs du formulaire depuis le ViewModel
            title = viewModel.eventTitle
            description = viewModel.eventDescription
            date = viewModel.eventDate
            address = viewModel.eventAddress
            selectedImage = viewModel.eventImage
        }
    }
    
    // MARK: - Components
    
    private var header: some View {
        HStack {
            Text("Creation of an event")
                .font(.headline)
                .foregroundColor(.white)
                .padding()
            Spacer()
        }
        .background(Color.black)
    }
    
    private var formFields: some View {
        VStack(spacing: 25) {
            // Title field
            StyledTextField(placeholder: "New event", text: $title)
                .onChange(of: title) { newValue in
                    viewModel.eventTitle = newValue
                }
            
            // Description field
            StyledTextEditor(text: $description)
                .onChange(of: description) { newValue in
                    viewModel.eventDescription = newValue
                }
            
            // Date and time fields in a row
            HStack(spacing: 10) {
                // Date field
                StyledDatePicker(date: $date, components: [.date])
                    .environment(\.locale, Locale(identifier: "en_US"))
                    .onChange(of: date) { newValue in
                        viewModel.eventDate = newValue
                    }
                
                // Time field
                StyledDatePicker(date: $date, components: [.hourAndMinute])
            }

            // Address field
            StyledTextField(placeholder: "Enter full address", text: $address)
                .onChange(of: address) { newValue in
                    viewModel.eventAddress = newValue
                }
        }
    }
    
    private var imageButtons: some View {
        VStack {
            HStack(spacing: 30) {
                // Camera button
                Button(action: {
                    // D'abord vérifier l'autorisation de la caméra
                    Task { @MainActor in
                        print("⚠️ DEBUG: Début vérification permission caméra")
                        // Vérifier l'autorisation à la demande de façon asynchrone
                        await checkCameraPermissionAsync()
                        
                        print("⚠️ DEBUG: Permission caméra après vérification: \(viewModel.cameraPermissionGranted)")
                        if viewModel.cameraPermissionGranted {
                            print("⚠️ DEBUG: Affichage de la caméra")
                            self.showCamera = true
                        } else if !viewModel.errorMessage.isEmpty {
                            self.permissionAlertType = .camera
                            self.showingPermissionAlert = true
                        }
                    }
                }) {
                    Image(systemName: "camera.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .frame(width: 52, height: 52)
                        .foregroundColor(.white)
                        .background(Color("Red"))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
                
                // Attach photo button
                Button(action: {
                    // D'abord vérifier l'autorisation de la photothèque
                    Task { @MainActor in
                        print("⚠️ DEBUG: Début vérification permission photothèque")
                        // Vérifier l'autorisation à la demande de façon asynchrone
                        await checkPhotoLibraryPermissionAsync()
                        
                        print("⚠️ DEBUG: Permission photothèque après vérification: \(viewModel.photoLibraryPermissionGranted)")
                        if viewModel.photoLibraryPermissionGranted {
                            print("⚠️ DEBUG: Affichage du sélecteur d'images")
                            self.showImagePicker = true
                        } else if !viewModel.errorMessage.isEmpty {
                            self.permissionAlertType = .photoLibrary
                            self.showingPermissionAlert = true
                        }
                    }
                }) {
                    Image(systemName: "photo.fill")
                        .resizable()
                        .scaledToFit()
                        .padding(12)
                        .frame(width: 52, height: 52)
                        .foregroundColor(.white)
                        .background(Color("Red"))
                        .clipShape(Circle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.top, 20)
            
            // Image preview
            if let selectedImage = selectedImage {
                VStack {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(10)
                        .padding(.top, 10)
                        .overlay(
                            Button(action: {
                                 print("⚠️ DEBUG: Suppression de l'image sélectionnée")
                                 self.selectedImage = nil
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .font(.title)
                                    .padding(8)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Circle())
                            }
                            .padding(8),
                            alignment: .topTrailing
                        )
                        .overlay(
                            Group {
                                switch viewModel.imageUploadState {
                                case .uploading(let progress):
                                    ProgressView(value: progress, total: 1.0)
                                        .progressViewStyle(LinearProgressViewStyle(tint: Color("Red")))
                                        .padding()
                                        .background(Color.black.opacity(0.5))
                                case .failure:
                                    Text("Échec de l'upload")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.red.opacity(0.8))
                                        .cornerRadius(5)
                                case .success:
                                    Label("Uploadée avec succès", systemImage: "checkmark.circle.fill")
                                        .foregroundColor(.white)
                                        .padding(8)
                                        .background(Color.green.opacity(0.8))
                                        .cornerRadius(5)
                                default:
                                    EmptyView()
                                }
                            }
                            .animation(.easeInOut, value: viewModel.imageUploadState)
                            .padding(),
                            alignment: .bottom
                        )
                    
                    Text("Image sélectionnée")
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding(.top, 4)
                }
                .transition(.opacity)
            }
        }
    }
    
    private var validateButton: some View {
        Button(action: {
            Task {
                await submitEvent()
            }
        }) {
            Text("Validate")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color("Red"))
                .cornerRadius(5)
        }
        .padding()
    }
    
    // MARK: - Methods
    
    private func submitEvent() async {
        print("⚠️ DEBUG: Début submitEvent - Thread: \(Thread.current.isMainThread ? "Main" : "Background")")
        print("⚠️ DEBUG: État avant soumission - Image: \(selectedImage != nil), Adresse: \(address)")
        
        // Appel à la méthode du ViewModel pour créer l'événement
        let success = await viewModel.createEvent()
        
        // Gestion du résultat
        print("⚠️ DEBUG: Résultat de createEvent: \(success)")
        if success {
            dismiss()
        } else if !viewModel.errorMessage.isEmpty {
            alertTitle = "Error"
            alertMessage = viewModel.errorMessage
            showingAlert = true
        }
    }
    
    /// Génère une alerte pour les autorisations
    /// Vérifie la permission d'accès à la caméra de façon asynchrone
    private func checkCameraPermissionAsync() async {
        print("⚠️ DEBUG: checkCameraPermissionAsync - Début")
        // Appeler la méthode synchrone du viewModel qui gère la logique de demande
        viewModel.checkCameraPermission()
        
        // Au lieu d'une attente fixe, attendre que la valeur soit mise à jour
        // en vérifiant périodiquement
        let startTime = Date()
        let timeout = TimeInterval(2.0) // 2 secondes maximum d'attente
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Si la permission est accordée, sortir de la boucle
            if viewModel.cameraPermissionGranted {
                print("✅ DEBUG: Permission caméra accordée")
                break
            }
            // Si un message d'erreur est défini, cela signifie que la permission a été refusée
            if !viewModel.errorMessage.isEmpty {
                print("❌ DEBUG: Permission caméra refusée: \(viewModel.errorMessage)")
                break
            }
            // Attendre un peu avant de vérifier à nouveau
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
        }
        
        print("⚠️ DEBUG: checkCameraPermissionAsync - Résultat: \(viewModel.cameraPermissionGranted)")
        
        // Si la permission est accordée après l'attente, afficher la caméra
        if viewModel.cameraPermissionGranted {
            self.showCamera = true
        } else if !viewModel.errorMessage.isEmpty {
            self.permissionAlertType = .camera
            self.showingPermissionAlert = true
        }
    }
    
    /// Vérifie la permission d'accès à la photothèque de façon asynchrone
    private func checkPhotoLibraryPermissionAsync() async {
        print("⚠️ DEBUG: checkPhotoLibraryPermissionAsync - Début")
        // Appeler la méthode synchrone du viewModel qui gère la logique de demande
        viewModel.checkPhotoLibraryPermission()
        
        // Au lieu d'une attente fixe, attendre que la valeur soit mise à jour
        // en vérifiant périodiquement
        let startTime = Date()
        let timeout = TimeInterval(2.0) // 2 secondes maximum d'attente
        
        while Date().timeIntervalSince(startTime) < timeout {
            // Si la permission est accordée, sortir de la boucle
            if viewModel.photoLibraryPermissionGranted {
                print("✅ DEBUG: Permission photothèque accordée")
                break
            }
            // Si un message d'erreur est défini, cela signifie que la permission a été refusée
            if !viewModel.errorMessage.isEmpty {
                print("❌ DEBUG: Permission photothèque refusée: \(viewModel.errorMessage)")
                break
            }
            // Attendre un peu avant de vérifier à nouveau
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconde
        }
        
        print("⚠️ DEBUG: checkPhotoLibraryPermissionAsync - Résultat: \(viewModel.photoLibraryPermissionGranted)")
        
        // Si la permission est accordée après l'attente, afficher le sélecteur d'images
        if viewModel.photoLibraryPermissionGranted {
            self.showImagePicker = true
        } else if !viewModel.errorMessage.isEmpty {
            self.permissionAlertType = .photoLibrary
            self.showingPermissionAlert = true
        }
    }
    
    private func getPermissionAlert(type: PermissionAlertType) -> Alert {
        let title: String
        let message: String
        
        switch type {
        case .camera:
            title = "Autorisation d'accès à la caméra"
            message = "Pour prendre des photos pour vos événements, Eventorias a besoin d'accéder à votre caméra. Vous pouvez modifier ce paramètre dans les Réglages."
        case .photoLibrary:
            title = "Autorisation d'accès aux photos"
            message = "Pour sélectionner des images pour vos événements, Eventorias a besoin d'accéder à vos photos. Vous pouvez modifier ce paramètre dans les Réglages."
        }
        
        return Alert(
            title: Text(title),
            message: Text(message),
            primaryButton: .default(Text("Ouvrir les Réglages")) {
                viewModel.openAppSettings()
            },
            secondaryButton: .cancel(Text("Annuler"))
        )
    }
}

// MARK: - Preview

struct EventCreationView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            EventCreationView(eventViewModel: EventViewModel())
        }
    }
}

// MARK: - Helper Views

// Utilise UIImagePickerController au lieu de PHPickerViewController pour plus de stabilité
struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) private var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: PHPickerView
        
        init(parent: PHPickerView) {
            self.parent = parent
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // S'assurer que nous avons une image valide
            if let image = info[.originalImage] as? UIImage {
                // Mettre à jour l'image sur le thread principal
                DispatchQueue.main.async { [weak self] in
                    self?.parent.image = image
                }
            }
            
            // Fermer le picker
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Gérer l'annulation
            picker.dismiss(animated: true)
        }
    }
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        picker.allowsEditing = true // Permet à l'utilisateur de recadrer l'image
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
            super.init()
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Utiliser l'image éditée si disponible, sinon l'originale
            let selectedImage: UIImage?
            if let editedImage = info[.editedImage] as? UIImage {
                selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                selectedImage = originalImage
            } else {
                selectedImage = nil
            }
            
            // Mise à jour sur le thread principal pour éviter les problèmes de concurrence
            DispatchQueue.main.async { [weak self] in 
                self?.parent.image = selectedImage
                picker.dismiss(animated: true) {
                    // Assurez-vous que le dismissal est terminé avant de continuer
                    DispatchQueue.main.async {
                        self?.parent.presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // Fermer l'interface caméra de manière sécurisée
            picker.dismiss(animated: true) { [weak self] in
                DispatchQueue.main.async {
                    self?.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}
