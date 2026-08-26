import SwiftUI

@main struct AniNovaApp: App {
    @StateObject private var container = AppContainer()
    var body: some Scene { WindowGroup { RootView().environmentObject(container) } }
}

@MainActor final class AppContainer: ObservableObject {
    let keychain = KeychainStore()
    let progress = ProgressStore()
    let repository: AnixartRepository
    let auth: AuthManager
    @AppStorage("appearance") var appearance = "system"
    init() {
        let api = APIClient(tokenProvider: keychain)
        repository = AnixartRepository(api: api)
        auth = AuthManager(keychain: keychain, repository: repository)
    }
}

extension KeychainStore: TokenProviding { var token: String? { readToken() } }

