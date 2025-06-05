//
//  EventCreationView.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 04/06/2025.
//

import SwiftUI
import PhotosUI
import Combine

struct EventCreationView: View {
    // MARK: - Properties
    
    @StateObject private var viewModel: EventCreationViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Image picker state
    @State private var showImagePicker = false
    @State private var showCamera = false
    @State private var showImageSourceOptions = false
    
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
        .sheet(isPresented: $showImagePicker) {
            PHPickerView(image: $selectedImage)
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraView(image: $selectedImage)
                .edgesIgnoringSafeArea(.all)
        }
        .onChange(of: selectedImage) { newImage in
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
                    self.showCamera = true
                }) {
                    Image("Button - Camera")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(.black)
                }
                // Attach photo button
                Button(action: {
                    self.showImagePicker = true
                }) {
                    Image("Button - Attach photo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 52, height: 52)
                        .foregroundColor(.white)
                }
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
        // Appel à la méthode du ViewModel pour créer l'événement
        let success = await viewModel.createEvent()
        
        // Gestion du résultat
        if success {
            dismiss()
        } else if !viewModel.errorMessage.isEmpty {
            alertTitle = "Error"
            alertMessage = viewModel.errorMessage
            showingAlert = true
        }
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

struct PHPickerView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PHPickerView
        
        init(_ parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let itemProvider = results.first?.itemProvider, itemProvider.canLoadObject(ofClass: UIImage.self) else {
                return
            }
            
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                DispatchQueue.main.async {
                    guard let self = self, let image = image as? UIImage else { return }
                    self.parent.image = image
                }
            }
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
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
