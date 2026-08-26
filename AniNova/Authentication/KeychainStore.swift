import Foundation
import Security

final class KeychainStore {
    private let service = "com.example.AniNova"
    private let account = "anixart.session.token"
    func readToken() -> String? {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecReturnData as String: true]
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
    func save(token: String) throws {
        delete()
        let attributes: [String: Any] = [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account, kSecValueData as String: Data(token.utf8), kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
        guard SecItemAdd(attributes as CFDictionary, nil) == errSecSuccess else { throw APIError.transport("keychain") }
    }
    func delete() { SecItemDelete([kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: account] as CFDictionary) }
}

@MainActor final class AuthManager: ObservableObject {
    enum State { case restoring, unauthenticated, authenticated(Profile) }
    @Published private(set) var state: State = .restoring
    private let keychain: KeychainStore
    private let repository: AnixartRepository
    private(set) var token: String?
    init(keychain: KeychainStore, repository: AnixartRepository) { self.keychain = keychain; self.repository = repository; self.token = keychain.readToken() }
    func restore() async {
        guard token != nil else { state = .unauthenticated; return }
        do { let id = UserDefaults.standard.integer(forKey: "anixart.profile.id"); guard id > 0, let profile = try await repository.profile(id: id).profile else { throw APIError.decoding }; state = .authenticated(profile) }
        catch { logout() }
    }
    func signIn(login: String, password: String) async throws {
        let response = try await repository.signIn(login: login, password: password)
        guard response.code == 0, let newToken = response.profileToken?.token, let profile = response.profile else { throw APIError.server(code: response.code) }
        try keychain.save(token: newToken); UserDefaults.standard.set(profile.id, forKey: "anixart.profile.id"); token = newToken; state = .authenticated(profile)
    }
    func logout() { keychain.delete(); UserDefaults.standard.removeObject(forKey: "anixart.profile.id"); token = nil; state = .unauthenticated }
}

