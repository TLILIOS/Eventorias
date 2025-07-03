//
//  NotificationService.swift
//  Eventorias
//
//  Created on 03/07/2025.
//

import Foundation
import UserNotifications

/// Service gérant les notifications locales de l'application
class NotificationService: NotificationServiceProtocol {
    
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // Catégories de notifications
    private enum NotificationCategory: String {
        case eventReminder = "EVENT_REMINDER"
        case eventUpdate = "EVENT_UPDATE"
    }
    
    // Identifiants pour les actions sur les notifications
    private enum NotificationAction: String {
        case view = "VIEW_ACTION"
        case dismiss = "DISMISS_ACTION"
    }
    
    init() {
        setupNotificationCategories()
    }
    
    // Configure les catégories et actions de notifications
    private func setupNotificationCategories() {
        // Actions pour les notifications d'événements
        let viewAction = UNNotificationAction(
            identifier: NotificationAction.view.rawValue,
            title: "Voir l'événement",
            options: .foreground
        )
        
        let dismissAction = UNNotificationAction(
            identifier: NotificationAction.dismiss.rawValue,
            title: "Ignorer",
            options: .destructive
        )
        
        // Catégorie pour les rappels d'événements
        let reminderCategory = UNNotificationCategory(
            identifier: NotificationCategory.eventReminder.rawValue,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Catégorie pour les mises à jour d'événements
        let updateCategory = UNNotificationCategory(
            identifier: NotificationCategory.eventUpdate.rawValue,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: .customDismissAction
        )
        
        // Enregistrement des catégories
        notificationCenter.setNotificationCategories([reminderCategory, updateCategory])
    }
    
    // MARK: - NotificationServiceProtocol
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("❌ Erreur lors de la demande d'autorisation de notifications: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(granted)
        }
    }
    
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                completion(settings.authorizationStatus)
            }
        }
    }
    
    func scheduleEventNotification(for event: Event, timeInterval: TimeInterval = 24 * 60 * 60, completion: @escaping (Bool) -> Void) {
        guard let eventId = event.id else {
            completion(false)
            return
        }
        
        // Vérifier si l'événement est dans le futur
        if event.date <= Date() {
            completion(false)
            return
        }
        
        // Calculer le moment où la notification doit être envoyée
        let triggerDate = event.date.addingTimeInterval(-timeInterval)
        
        // Ne pas planifier si la date de déclenchement est déjà passée
        if triggerDate <= Date() {
            completion(false)
            return
        }
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "Événement à venir"
        content.body = "Ne manquez pas \"\(event.title)\" qui commence le \(event.formattedDate)"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.eventReminder.rawValue
        
        // Ajouter des informations supplémentaires
        content.userInfo = [
            "eventId": eventId,
            "title": event.title,
            "location": event.location
        ]
        
        // Créer le déclencheur basé sur la date calculée
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)
        
        // Créer et ajouter la demande de notification
        let request = UNNotificationRequest(
            identifier: "event_reminder_\(eventId)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la programmation de la notification: \(error.localizedDescription)")
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    func scheduleNotificationsForUpcomingEvents(events: [Event], completion: @escaping (Bool) -> Void) {
        // Filtrer les événements à venir
        let upcomingEvents = events.filter { $0.date > Date() }
        
        // Groupe de dispatch pour suivre la progression
        let dispatchGroup = DispatchGroup()
        var allSucceeded = true
        
        // Planifier une notification pour chaque événement à venir
        for event in upcomingEvents {
            dispatchGroup.enter()
            
            // Planification de la notification 24h avant l'événement
            scheduleEventNotification(for: event, timeInterval: 24 * 60 * 60) { success in
                if !success {
                    allSucceeded = false
                }
                dispatchGroup.leave()
            }
            
            // Si l'événement est dans plus de 7 jours, planifier également une notification 7 jours avant
            if let eventDate = event.date as Date?, eventDate.timeIntervalSinceNow > 7 * 24 * 60 * 60 {
                dispatchGroup.enter()
                scheduleEventNotification(for: event, timeInterval: 7 * 24 * 60 * 60) { success in
                    if !success {
                        allSucceeded = false
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        // Appeler le completion handler une fois que toutes les notifications sont planifiées
        dispatchGroup.notify(queue: .main) {
            completion(allSucceeded && !upcomingEvents.isEmpty)
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func cancelNotification(for eventId: String) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ["event_reminder_\(eventId)"])
    }
    
    // MARK: - Helper Methods
    
    /// Notifie l'utilisateur d'une mise à jour d'un événement
    /// - Parameter event: L'événement mis à jour
    func notifyEventUpdate(event: Event) {
        guard let eventId = event.id else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Mise à jour d'événement"
        content.body = "L'événement \"\(event.title)\" a été mis à jour"
        content.sound = .default
        content.categoryIdentifier = NotificationCategory.eventUpdate.rawValue
        content.userInfo = ["eventId": eventId]
        
        // Déclenchement immédiat (après 1 seconde)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "event_update_\(eventId)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Erreur lors de la notification de mise à jour: \(error.localizedDescription)")
            }
        }
    }
}
