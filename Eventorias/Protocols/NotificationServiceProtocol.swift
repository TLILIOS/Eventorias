//
//  NotificationServiceProtocol.swift
//  Eventorias
//
//  Created on 03/07/2025.
//

import Foundation
import UserNotifications

/// Protocole définissant les fonctionnalités d'un service de notifications
protocol NotificationServiceProtocol {
    /// Demande l'autorisation pour envoyer des notifications
    /// - Parameter completion: Appelé lorsque l'utilisateur a répondu à la demande d'autorisation
    func requestAuthorization(completion: @escaping (Bool) -> Void)
    
    /// Vérifie si l'application est autorisée à envoyer des notifications
    /// - Parameter completion: Appelé avec le statut d'autorisation actuel
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void)
    
    /// Planifie une notification pour un événement à venir
    /// - Parameters:
    ///   - event: L'événement pour lequel planifier une notification
    ///   - timeInterval: Délai en secondes avant l'événement (par défaut: 24 heures)
    ///   - completion: Appelé lorsque la notification a été planifiée
    func scheduleEventNotification(for event: Event, timeInterval: TimeInterval, completion: @escaping (Bool) -> Void)
    
    /// Planifie des notifications pour tous les événements à venir
    /// - Parameters:
    ///   - events: Liste des événements pour lesquels planifier des notifications
    ///   - completion: Appelé une fois que toutes les notifications ont été planifiées
    func scheduleNotificationsForUpcomingEvents(events: [Event], completion: @escaping (Bool) -> Void)
    
    /// Annule toutes les notifications programmées
    func cancelAllNotifications()
    
    /// Annule une notification spécifique
    /// - Parameter eventId: L'identifiant de l'événement dont la notification doit être annulée
    func cancelNotification(for eventId: String)
}
