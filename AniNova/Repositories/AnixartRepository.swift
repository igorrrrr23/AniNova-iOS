import Foundation

struct ReleaseFilter: Codable { let statusId: Int?; let categoryId: Int?; let sort: Int? }
struct SearchBody: Codable { let query: String; let searchBy: Int }

final class AnixartRepository {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    func signIn(login: String, password: String) async throws -> LoginResponse { try await api.form("/auth/signIn", values: ["login": login, "password": password]) }
    func myProfile() async throws -> ProfileResponse { try await api.sendEmpty("/profile/info", authenticated: true) }
    func profile(id: Int) async throws -> ProfileResponse { try await api.sendEmpty("/profile/\(id)", authenticated: true) }
    func release(id: Int) async throws -> ReleaseResponse { try await api.sendEmpty("/release/\(id)", query: ["extended_mode": "true"], authenticated: true) }
    func releases(page: Int, filter: ReleaseFilter) async throws -> Page<Release> { try await api.send("/filter/\(page)", method: .post, body: filter, authenticated: true) }
    func searchReleases(query: String, page: Int) async throws -> Page<Release> { try await api.send("/search/releases/\(page)", method: .post, body: SearchBody(query: query, searchBy: 0), apiV2: true, authenticated: true) }
    func searchProfiles(query: String, page: Int) async throws -> Page<Profile> { try await api.send("/search/profiles/\(page)", method: .post, body: SearchBody(query: query, searchBy: 0), authenticated: true) }
    func searchCollections(query: String, page: Int) async throws -> Page<Collection> { try await api.send("/search/collections/\(page)", method: .post, body: SearchBody(query: query, searchBy: 0), authenticated: true) }
    func bookmarks(profileID: Int, status: BookmarkStatus, page: Int) async throws -> Page<Release> { try await api.sendEmpty("/profile/list/all/\(profileID)/\(status.rawValue)/\(page)", authenticated: true) }
    func updateBookmark(releaseID: Int, status: BookmarkStatus) async throws -> APIResponse { try await api.sendEmpty("/profile/list/add/\(status.rawValue)/\(releaseID)", authenticated: true) }
    func removeBookmark(releaseID: Int, status: BookmarkStatus) async throws -> APIResponse { try await api.sendEmpty("/profile/list/delete/\(status.rawValue)/\(releaseID)", authenticated: true) }
    func dubbers(releaseID: Int) async throws -> EpisodeTypesResponse { try await api.sendEmpty("/episode/\(releaseID)", authenticated: true) }
    func sources(releaseID: Int, dubberID: Int) async throws -> SourcesResponse { try await api.sendEmpty("/episode/\(releaseID)/\(dubberID)", authenticated: true) }
    func episodes(releaseID: Int, dubberID: Int, sourceID: Int) async throws -> EpisodesResponse { try await api.sendEmpty("/episode/\(releaseID)/\(dubberID)/\(sourceID)", query: ["sort": "1"], authenticated: true) }
    func markEpisode(releaseID: Int, sourceID: Int, position: Int, watched: Bool) async throws -> APIResponse { try await api.sendEmpty("/episode/\(watched ? "watch" : "unwatch")/\(releaseID)/\(sourceID)/\(position)", authenticated: true) }
    func addToHistory(releaseID: Int, sourceID: Int, position: Int) async throws -> APIResponse { try await api.sendEmpty("/history/add/\(releaseID)/\(sourceID)/\(position)", authenticated: true) }
    func comments(releaseID: Int, page: Int) async throws -> Page<ReleaseComment> { try await api.sendEmpty("/release/comment/all/\(releaseID)/\(page)", query: ["sort": "1"], authenticated: true) }
    func related(relatedID: Int, page: Int) async throws -> Page<Release> { try await api.sendEmpty("/related/\(relatedID)/\(page)", apiV2: true, authenticated: true) }
    func notifications(page: Int) async throws -> NotificationsResponse { try await api.sendEmpty("/notification/all/\(page)", authenticated: true) }
    func readNotifications() async throws -> APIResponse { try await api.sendEmpty("/notification/read", authenticated: true) }
}

struct Collection: Codable, Identifiable, Hashable { let id: Int; let title: String?; let name: String? }

