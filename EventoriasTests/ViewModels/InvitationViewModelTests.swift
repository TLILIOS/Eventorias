//
//  InvitationViewModelTests.swift
//  EventoriasTests
//
//  Created on 03/07/2025
//

import XCTest
import Combine
@testable import Eventorias

@MainActor
class InvitationViewModelTests: XCTestCase {
    // MARK: - Properties
    private var viewModel: InvitationViewModel!
    private var mockFirestoreService: MockFirestoreService!
    private var mockAuthService: MockAuthenticationService!
    private var cancellables: Set<AnyCancellable>!
    
    // MARK: - Setup & Teardown
    
    override func setUp() {
        super.setUp()
        mockFirestoreService = MockFirestoreService()
        mockAuthService = MockAuthenticationService()
        
        // Réinitialisation des mocks pour garantir l'isolation entre les tests
        mockFirestoreService.resetFlags()
        
        viewModel = InvitationViewModel(
            firestoreService: mockFirestoreService,
            authService: mockAuthService
        )
        cancellables = []
    }
    
    override func tearDown() {
        // Libérer les ressources
        viewModel = nil
        mockFirestoreService = nil
        mockAuthService = nil
        cancellables = nil
        super.tearDown()
    }
    
    // MARK: - Helper Methods
    
    private func createMockInvitation(id: String = "inv-1",
                                     eventId: String = "event-1",
                                     inviterId: String = "inviter-1",
                                     inviteeId: String = "invitee-1",
                                     inviteeName: String = "Test Invitee",
                                     status: InvitationStatus = .pending) -> Invitation {
        var invitation = Invitation(
            id: id,
            eventId: eventId,
            inviterId: inviterId,
            inviteeId: inviteeId,
            inviteeName: inviteeName,
            inviteeEmail: "test@example.com",
            status: status,
            message: "Test invitation",
            sentAt: Date()
        )
        return invitation
    }
    
    // MARK: - Test Load Invitations
    
    func testLoadInvitations_WhenSuccessful_ShouldPopulateInvitationsList() async {
        // Given
        let eventId = "test-event-id"
        let mockInvitations = [
            createMockInvitation(id: "inv-1", eventId: eventId),
            createMockInvitation(id: "inv-2", eventId: eventId)
        ]
        
        // Configuration du mock pour retourner des invitations
        let mockMethod = MockMethod<String, [Invitation]>(name: "getEventInvitations")
        mockMethod.whenCalled(with: eventId).thenReturn(mockInvitations)
        mockFirestoreService.mockGetEventInvitations = mockMethod
        
        // When
        await viewModel.loadInvitations(for: eventId)
        
        // Then
        XCTAssertEqual(viewModel.eventInvitations.count, 2)
        XCTAssertEqual(viewModel.eventInvitations[0].id, "inv-1")
        XCTAssertEqual(viewModel.eventInvitations[1].id, "inv-2")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertEqual(viewModel.errorMessage, "")
    }
    
    func testLoadInvitations_WhenFails_ShouldSetErrorMessage() async {
        // Given
        let eventId = "test-event-id"
        let mockError = NSError(domain: "FirestoreError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Invitations non trouvées"])
        
        // Configuration du mock pour lancer une erreur
        let mockMethod = MockMethod<String, [Invitation]>(name: "getEventInvitations")
        mockMethod.whenCalled(with: eventId).thenThrow(mockError)
        mockFirestoreService.mockGetEventInvitations = mockMethod
        
        // When
        await viewModel.loadInvitations(for: eventId)
        
        // Then
        XCTAssertTrue(viewModel.eventInvitations.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertTrue(viewModel.errorMessage.contains("Impossible de charger les invitations"))
    }
    
    // MARK: - Test Create Invitation
    
    func testCreateInvitation_WhenSuccessful_ShouldAddInvitationToList() async throws {
        // Given
        let eventId = "test-event-id"
        let inviteeId = "invitee-id"
        let inviteeName = "Test Invitee"
        let email = "test@example.com"
        let message = "Test invitation message"
        
        // Configurer le mock auth service pour simuler un utilisateur connecté
        let mockUser = MockUser(uid: "current-user-id", email: "current@example.com", displayName: "Current User")
        mockAuthService.currentUserMock = mockUser
        
        // Configurer le mock firestore service pour simuler une création réussie
        mockFirestoreService.shouldThrowError = false
        
        // When
        try await viewModel.createInvitation(
            eventId: eventId,
            inviteeId: inviteeId,
            inviteeName: inviteeName,
            email: email,
            message: message
        )
        
        // Then
        XCTAssertEqual(viewModel.eventInvitations.count, 1)
        XCTAssertEqual(viewModel.eventInvitations[0].eventId, eventId)
        XCTAssertEqual(viewModel.eventInvitations[0].inviteeId, inviteeId)
        XCTAssertEqual(viewModel.eventInvitations[0].inviteeName, inviteeName)
        XCTAssertEqual(viewModel.eventInvitations[0].inviteeEmail, email)
        XCTAssertEqual(viewModel.eventInvitations[0].message, message)
        XCTAssertEqual(viewModel.eventInvitations[0].status, .pending)
    }
    
    func testCreateInvitation_WhenUserNotLoggedIn_ShouldThrowError() async {
        // Given
        let eventId = "test-event-id"
        let inviteeId = "invitee-id"
        let inviteeName = "Test Invitee"
        
        // Configurer le mock auth service pour simuler aucun utilisateur connecté
        mockAuthService.currentUserMock = nil
        
        // When / Then
        do {
            try await viewModel.createInvitation(
                eventId: eventId,
                inviteeId: inviteeId,
                inviteeName: inviteeName
            )
            XCTFail("L'opération devrait échouer car aucun utilisateur n'est connecté")
        } catch {
            // Vérifier que l'erreur est bien celle attendue
            XCTAssertEqual((error as NSError).domain, "InvitationViewModel")
            XCTAssertEqual((error as NSError).code, 401)
            XCTAssertTrue((error as NSError).localizedDescription.contains("Utilisateur non connecté"))
        }
    }
    
    func testCreateInvitation_WhenFirestoreErrors_ShouldPropagateError() async {
        // Given
        let eventId = "test-event-id"
        let inviteeId = "invitee-id"
        let inviteeName = "Test Invitee"
        
        // Configurer le mock auth service pour simuler un utilisateur connecté
        let mockUser = MockUser(uid: "current-user-id", email: "current@example.com", displayName: "Current User")
        mockAuthService.currentUserMock = mockUser
        
        // Configurer le mock firestore service pour simuler une erreur
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur réseau"])
        
        // When / Then
        do {
            try await viewModel.createInvitation(
                eventId: eventId,
                inviteeId: inviteeId,
                inviteeName: inviteeName
            )
            XCTFail("L'opération devrait échouer à cause de l'erreur Firestore")
        } catch {
            // Vérifier que l'erreur est bien celle propagée
            XCTAssertEqual((error as NSError).domain, "FirestoreError")
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual((error as NSError).localizedDescription, "Erreur réseau")
        }
    }
    
    // MARK: - Test Update Invitation Status
    
    func testUpdateInvitationStatus_WhenSuccessful_ShouldUpdateStatus() async throws {
        // Given
        let invitation = createMockInvitation()
        viewModel.eventInvitations = [invitation]
        
        // Configurer le mock firestore service pour simuler une mise à jour réussie
        mockFirestoreService.shouldThrowError = false
        
        // When
        try await viewModel.updateInvitationStatus(invitation: invitation, newStatus: .accepted)
        
        // Then
        XCTAssertEqual(viewModel.eventInvitations.count, 1)
        XCTAssertEqual(viewModel.eventInvitations[0].status, .accepted)
    }
    
    func testUpdateInvitationStatus_WhenInvitationNotFound_ShouldThrowError() async {
        // Given
        let invitation = createMockInvitation(id: "non-existent-id")
        viewModel.eventInvitations = [createMockInvitation(id: "different-id")]
        
        // When / Then
        do {
            try await viewModel.updateInvitationStatus(invitation: invitation, newStatus: .accepted)
            XCTFail("L'opération devrait échouer car l'invitation n'existe pas")
        } catch {
            // Vérifier que l'erreur est bien celle attendue
            XCTAssertEqual((error as NSError).domain, "InvitationViewModel")
            XCTAssertEqual((error as NSError).code, 404)
            XCTAssertTrue((error as NSError).localizedDescription.contains("Invitation introuvable"))
        }
    }
    
    func testUpdateInvitationStatus_WhenFirestoreErrors_ShouldPropagateError() async {
        // Given
        let invitation = createMockInvitation()
        viewModel.eventInvitations = [invitation]
        
        // Configurer le mock firestore service pour simuler une erreur
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur de mise à jour"])
        
        // When / Then
        do {
            try await viewModel.updateInvitationStatus(invitation: invitation, newStatus: .declined)
            XCTFail("L'opération devrait échouer à cause de l'erreur Firestore")
        } catch {
            // Vérifier que l'erreur est bien celle propagée
            XCTAssertEqual((error as NSError).domain, "FirestoreError")
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual((error as NSError).localizedDescription, "Erreur de mise à jour")
        }
    }
    
    // MARK: - Test Remove Invitation
    
    func testRemoveInvitation_WhenSuccessful_ShouldRemoveFromList() async throws {
        // Given
        let invitation = createMockInvitation()
        viewModel.eventInvitations = [invitation]
        
        // Configurer le mock firestore service pour simuler une suppression réussie
        mockFirestoreService.shouldThrowError = false
        
        // When
        try await viewModel.removeInvitation(invitation: invitation)
        
        // Then
        XCTAssertTrue(viewModel.eventInvitations.isEmpty)
    }
    
    func testRemoveInvitation_WhenInvitationHasNoId_ShouldThrowError() async {
        // Given
        var invitation = createMockInvitation()
        invitation.id = nil  // Invitation sans ID
        viewModel.eventInvitations = [invitation]
        
        // When / Then
        do {
            try await viewModel.removeInvitation(invitation: invitation)
            XCTFail("L'opération devrait échouer car l'invitation n'a pas d'ID")
        } catch {
            // Vérifier que l'erreur est bien celle attendue
            XCTAssertEqual((error as NSError).domain, "InvitationViewModel")
            XCTAssertEqual((error as NSError).code, 404)
            XCTAssertTrue((error as NSError).localizedDescription.contains("ID d'invitation invalide"))
        }
    }
    
    func testRemoveInvitation_WhenFirestoreErrors_ShouldPropagateError() async {
        // Given
        let invitation = createMockInvitation()
        viewModel.eventInvitations = [invitation]
        
        // Configurer le mock firestore service pour simuler une erreur
        mockFirestoreService.shouldThrowError = true
        mockFirestoreService.mockError = NSError(domain: "FirestoreError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Erreur de suppression"])
        
        // When / Then
        do {
            try await viewModel.removeInvitation(invitation: invitation)
            XCTFail("L'opération devrait échouer à cause de l'erreur Firestore")
        } catch {
            // Vérifier que l'erreur est bien celle propagée
            XCTAssertEqual((error as NSError).domain, "FirestoreError")
            XCTAssertEqual((error as NSError).code, 500)
            XCTAssertEqual((error as NSError).localizedDescription, "Erreur de suppression")
        }
    }
    
    // MARK: - Test Helper Methods
    
    func testCanEditInvitation_WhenUserIsInviter_ShouldReturnTrue() {
        // Given
        let userId = "user-id"
        let invitation = createMockInvitation(inviterId: userId)
        
        // Configurer le mock auth service pour simuler l'utilisateur connecté
        let mockUser = MockUser(uid: userId, email: "user@example.com", displayName: "Test User")
        mockAuthService.currentUserMock = mockUser
        
        // When
        let canEdit = viewModel.canEditInvitation(invitation)
        
        // Then
        XCTAssertTrue(canEdit)
    }
    
    func testCanEditInvitation_WhenUserIsNotInviter_ShouldReturnFalse() {
        // Given
        let invitation = createMockInvitation(inviterId: "inviter-id")
        
        // Configurer le mock auth service pour simuler un autre utilisateur connecté
        let mockUser = MockUser(uid: "different-user-id", email: "other@example.com", displayName: "Other User")
        mockAuthService.currentUserMock = mockUser
        
        // When
        let canEdit = viewModel.canEditInvitation(invitation)
        
        // Then
        XCTAssertFalse(canEdit)
    }
    
    func testCanRespondToInvitation_WhenUserIsInvitee_ShouldReturnTrue() {
        // Given
        let userId = "user-id"
        let invitation = createMockInvitation(inviteeId: userId, status: .pending)
        
        // Configurer le mock auth service pour simuler l'utilisateur connecté
        let mockUser = MockUser(uid: userId, email: "user@example.com", displayName: "Test User")
        mockAuthService.currentUserMock = mockUser
        
        // When
        let canRespond = viewModel.canRespondToInvitation(invitation)
        
        // Then
        XCTAssertTrue(canRespond)
    }
    
    func testCanRespondToInvitation_WhenStatusNotPending_ShouldReturnFalse() {
        // Given
        let userId = "user-id"
        let invitation = createMockInvitation(inviteeId: userId, status: .accepted) // Status autre que pending
        
        // Configurer le mock auth service pour simuler l'utilisateur connecté
        let mockUser = MockUser(uid: userId, email: "user@example.com", displayName: "Test User")
        mockAuthService.currentUserMock = mockUser
        
        // When
        let canRespond = viewModel.canRespondToInvitation(invitation)
        
        // Then
        XCTAssertFalse(canRespond)
    }
}

// MARK: - MockMethod pour simuler les méthodes Firestore

class MockMethod<Input, Output> {
    private struct Call {
        let input: Input
        let output: Result<Output, Error>
    }
    
    let name: String
    private var calls: [Call] = []
    
    init(name: String) {
        self.name = name
    }
    
    func whenCalled(with input: Input) -> Self {
        return self
    }
    
    func thenReturn(_ output: Output) {
        calls.append(Call(input: calls.last?.input ?? ((calls.isEmpty && calls.count == 0) ? 0 as! Input : calls.last!.input), output: .success(output)))
    }
    
    func thenThrow(_ error: Error) {
        calls.append(Call(input: calls.last?.input ?? ((calls.isEmpty && calls.count == 0) ? 0 as! Input : calls.last!.input), output: .failure(error)))
    }
    
    func call(_ input: Input) throws -> Output {
        // Pour simplifier, on retourne la première réponse définie
        guard let call = calls.first else {
            fatalError("MockMethod \(name) appelée sans comportement défini")
        }
        
        switch call.output {
        case .success(let output):
            return output
        case .failure(let error):
            throw error
        }
    }
}

// Étendre MockFirestoreService pour ajouter la méthode spécifique aux invitations
extension MockFirestoreService {
    func getEventInvitations(eventId: String) async throws -> [Invitation] {
        if let mockMethod = mockGetEventInvitations {
            return try mockMethod.call(eventId)
        }
        
        if shouldThrowError {
            throw mockError
        }
        
        // Réponse par défaut si aucun mock spécifique n'est défini
        return []
    }
    
    func createInvitation(_ invitation: Invitation) async throws {
        if shouldThrowError {
            throw mockError
        }
        // Simuler une création réussie - pas besoin de faire plus
    }
    
    func updateInvitation(_ invitation: Invitation) async throws {
        if shouldThrowError {
            throw mockError
        }
        // Simuler une mise à jour réussie - pas besoin de faire plus
    }
    
    func deleteInvitation(_ invitationId: String) async throws {
        if shouldThrowError {
            throw mockError
        }
        // Simuler une suppression réussie - pas besoin de faire plus
    }
}
