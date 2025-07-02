//
//  ProfileImageSelector.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 26/06/2025.
//

import SwiftUI
import PhotosUI

struct ProfileImageSelector: View {
    @Binding var selectedImage: UIImage?
    @State private var photoItem: PhotosPickerItem?
    @State private var isShowingPhotoPicker = false
    var backgroundColor: Color = Color("DarkGray")

    var body: some View {
        HStack {
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80, height: 80)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.gray, lineWidth: 2))
                } else {
                    Circle()
                        .fill(backgroundColor)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "person.crop.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.gray)
                        )
                }
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Color("Red"))
                            .frame(width: 22, height: 22)
                            .overlay(
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.white)
                            )
                            .offset(x: 5, y: 5)
                    }
                }
                .frame(width: 80, height: 80)
            }
            
            Spacer()
            
            // Boutons d'action
            VStack(alignment: .leading, spacing: 10) {
                Button(action: {
                    isShowingPhotoPicker = true
                }) {
                    Text("Sélectionner une photo")
                        .font(.subheadline)
                        .foregroundColor(Color("Red"))
                }
                
                if selectedImage != nil {
                    Button(action: {
                        selectedImage = nil
                    }) {
                        Text("Supprimer la photo")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .photosPicker(isPresented: $isShowingPhotoPicker, selection: $photoItem)
        .onChange(of: photoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.selectedImage = image
                    }
                }
            }
        }
    }
}

// MARK: - Prévisualisations
#Preview {
    VStack {
        ProfileImageSelector(selectedImage: .constant(nil))
        ProfileImageSelector(selectedImage: .constant(UIImage(systemName: "person.circle.fill")))
    }
    .padding()
    .background(Color.black)
}
