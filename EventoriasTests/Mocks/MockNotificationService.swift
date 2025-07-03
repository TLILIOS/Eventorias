//
//  MockNotificationService.swift
//  EventoriasTests
//
//  Created on 03/07/2025.
//

import Foundation
import UserNotifications
@testable import Eventorias

class MockNotificationService: NotificationServiceProtocol {
    
    // Variables pour suivre les appels de méthodes
    var requestAuthorizationCalled = false
    var authorizationGranted = true
    var checkAuthorizationStatusCalled = false
    var scheduleEventNotificationCalled = false
    var scheduleNotificationsForUpcomingEventsCalled = false
    var cancelAllNotificationsCalled = false
    var cancelNotificationCalled = false
    
    // Variables pour stocker les paramètres passés aux méthodes
    var lastEventScheduled: Event?
    var lastTimeInterval: TimeInterval = 0
    var lastEventsScheduled: [Event] = []
    var lastEventIdCancelled: String?
    
    // Méthode pour réinitialiser les états du mock
    func reset() {
        requestAuthorizationCalled = false
        authorizationGranted = true
        checkAuthorizationStatusCalled = false
        scheduleEventNotificationCalled = false
        scheduleNotificationsForUpcomingEventsCalled = false
        cancelAllNotificationsCalled = false
        cancelNotificationCalled = false
        
        lastEventScheduled = nil
        lastTimeInterval = 0
        lastEventsScheduled = []
        lastEventIdCancelled = nil
    }
    
    // MARK: - Implementation du protocole NotificationServiceProtocol
    
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        requestAuthorizationCalled = true
        completion(authorizationGranted)
    }
    
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        checkAuthorizationStatusCalled = true
        completion(authorizationGranted ? .authorized : .denied)
    }
    
    func scheduleEventNotification(for event: Event, timeInterval: TimeInterval, completion: @escaping (Bool) -> Void) {
        scheduleEventNotificationCalled = true
        lastEventScheduled = event
        lastTimeInterval = timeInterval
        completion(true)
    }
    
    func scheduleNotificationsForUpcomingEvents(events: [Event], completion: @escaping (Bool) -> Void) {
        scheduleNotificationsForUpcomingEventsCalled = true
        lastEventsScheduled = events
        completion(true)
    }
    
    func cancelAllNotifications() {
        cancelAllNotificationsCalled = true
    }
    
    func cancelNotification(for eventId: String) {
        cancelNotificationCalled = true
        lastEventIdCancelled = eventId
    }
}
