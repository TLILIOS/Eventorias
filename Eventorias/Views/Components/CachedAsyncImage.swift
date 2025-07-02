//
//  CachedAsyncImage.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 28/06/2025.
//

import SwiftUI

/// Un composant qui charge et met en cache des images à partir d'URLs
struct CachedAsyncImage<Content: View>: View {
    private let url: URL?
    private let scale: CGFloat
    private let transaction: Transaction
    private let content: (AsyncImagePhase) -> Content
    
    @State private var phase: AsyncImagePhase = .empty
    @State private var isLoading: Bool = false
    
    /// Initialise le composant CachedAsyncImage
    /// - Parameters:
    ///   - url: L'URL de l'image à charger
    ///   - scale: L'échelle à appliquer à l'image
    ///   - transaction: La transaction SwiftUI à utiliser pour l'animation
    ///   - content: Le builder de vue pour tous les états (empty, success, failure)
    init(url: URL?,
         scale: CGFloat = 1.0,
         transaction: Transaction = Transaction(),
         @ViewBuilder content: @escaping (AsyncImagePhase) -> Content) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.content = content
    }
    
    var body: some View {
        content(phase)
            .onAppear {
                loadImage()
            }
    }
    
    private func loadImage() {
        guard !isLoading else { return }
        
        guard let url = url else {
            DispatchQueue.main.async {
                self.phase = .failure(NSError(domain: "CachedAsyncImage", code: -1, userInfo: [NSLocalizedDescriptionKey: "URL invalide"]))
            }
            return
        }
        
        let urlString = url.absoluteString
        
        // Vérifie si l'image est en cache
        if let cachedUIImage = ImageCache.shared.retrieve(forKey: urlString) {
            DispatchQueue.main.async {
                withTransaction(transaction) {
                    self.phase = .success(Image(uiImage: cachedUIImage))
                }
            }
            return
        }
        
        // Si non, on charge depuis l'URL
        isLoading = true
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            isLoading = false
            
            DispatchQueue.main.async {
                if let error = error {
                    withTransaction(transaction) {
                        self.phase = .failure(error)
                    }
                    return
                }
                
                guard let data = data else {
                    withTransaction(transaction) {
                        self.phase = .failure(NSError(domain: "CachedAsyncImage", code: -2, userInfo: [NSLocalizedDescriptionKey: "Données d'image invalides"]))
                    }
                    return
                }
                
                guard let uiImage = UIImage(data: data) else {
                    withTransaction(transaction) {
                        self.phase = .failure(NSError(domain: "CachedAsyncImage", code: -3, userInfo: [NSLocalizedDescriptionKey: "Impossible de créer l'UIImage"]))
                    }
                    return
                }
                
                // Stockage en cache
                ImageCache.shared.store(uiImage, forKey: urlString)
                
                // Mise à jour de l'UI
                withTransaction(transaction) {
                    self.phase = .success(Image(uiImage: uiImage))
                }
            }
        }.resume()
    }
}

// Pas besoin d'extension spécifique - le composant de base est déjà adapté

/// Une phase simulant AsyncImagePhase pour compatibilité
enum AsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error)
    
    var image: Image? {
        switch self {
        case .success(let image):
            return image
        default:
            return nil
        }
    }
}
