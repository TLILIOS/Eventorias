import Foundation
import Combine
@MainActor
protocol AuthenticationViewModelProtocol: ObservableObject {
    var email: String { get set }
    var password: String { get set }
    var userIsLoggedIn: Bool { get }
    var isLoading: Bool { get }
    var errorMessage: String? { get }

    @MainActor
    func signIn() async

    @MainActor
    func signOut() async
    
    @MainActor
    func quickSignIn() async
    
    @MainActor
    func signOutWithoutClearingForm() async

    func storeCredentialsExplicit(email: String, password: String)
    func loadStoredCredentials()
    func dismissError()
}
