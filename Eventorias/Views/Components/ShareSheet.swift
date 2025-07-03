//
//  ShareSheet.swift
//  Eventorias
//
//  Created on 03/07/2025.
//

import SwiftUI
import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let event: Event
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        // Création des éléments à partager
        
        // Créer un texte formaté pour partager l'événement
        let title = event.title
        let date = DateFormatter.localizedString(from: event.date, dateStyle: .medium, timeStyle: .short)
        let location = event.location
        
        let shareText = """
        \(title)
        Date: \(date)
        Lieu: \(location)
        
        Rejoignez-moi à cet événement via l'app Eventorias!
        """
        
        // Éléments à partager (texte, image si disponible)
        var itemsToShare: [Any] = [shareText]
        
        // Si une image est associée à l'événement, on essaie de la télécharger pour la partager
        if let imageURLString = event.imageURL, let imageURL = URL(string: imageURLString) {
            // Note: Dans une application réelle, nous devrions utiliser une méthode asynchrone
            // pour télécharger l'image, mais pour les besoins de cet exemple, nous n'incluons
            // que le texte et l'URL
            itemsToShare.append(imageURL)
        }
        
        // Créer l'UIActivityViewController avec les éléments à partager
        let activityViewController = UIActivityViewController(
            activityItems: itemsToShare,
            applicationActivities: nil
        )
        
        // Configurer les types d'activités à exclure (optionnel)
        activityViewController.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList
        ]
        
        return activityViewController
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Rien à mettre à jour ici car UIActivityViewController est statique une fois créé
    }
}
