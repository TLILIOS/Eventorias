//
//  ImageCache.swift
//  Eventorias
//
//  Created by TLiLi Hamdi on 28/06/2025.
//

import SwiftUI

/// Gestionnaire de cache pour les images
class ImageCache {
    static let shared = ImageCache()
    
    private var cache = NSCache<NSString, UIImage>()
    
    private init() {
        // Configuration de base du cache
        cache.countLimit = 100 // Limite le nombre d'images en cache
        cache.totalCostLimit = 1024 * 1024 * 100 // ~100 MB
    }
    
    /// Ajoute une image au cache
    func store(_ image: UIImage, forKey key: String) {
        cache.setObject(image, forKey: key as NSString)
    }
    
    /// Récupère une image du cache
    func retrieve(forKey key: String) -> UIImage? {
        return cache.object(forKey: key as NSString)
    }
    
    /// Supprime une image du cache
    func removeImage(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
    
    /// Vide tout le cache
    func clearCache() {
        cache.removeAllObjects()
    }
}
