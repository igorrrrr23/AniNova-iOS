import Foundation

struct ReleaseFilter: Codable {
    let statusId: Int?
    let categoryId: Int?
    let sort: Int?
}

struct SearchBody: Codable {
    let query: String
    let searchBy: Int
}

final class AnixartRepository {
    private let api: APIClient
    init(api: APIClient) { self.api = api }

    // MARK: - Auth

    func signIn(login: String, password: String) async throws -> LoginResponse {
        try await api.form("/auth/signIn", values: ["login": login, "password": password])
    }

    // MARK: - Profile

    func myProfile() async throws -> ProfileResponse {
        try await api.sendEmpty("/profile/info", authenticated: true)
    }

    func profile(id: Int) async throws -> ProfileResponse {
        try await api.sendEmpty("/profile/\(id)", authenticated: true)
    }

    func friends(profileID: Int, page: Int) async throws -> FriendsResponse {
        try await api.sendEmpty("/profile/friend/all/\(profileID)/\(page)", authenticated: true)
    }

    // MARK: - Releases

    func release(id: Int) async throws -> ReleaseResponse {
        try await api.sendEmpty("/release/\(id)", query: ["extended_mode": "true"], authenticated: true)
    }

    func releases(page: Int, filter: ReleaseFilter) async throws -> Page<Release> {
        try await api.send("/filter/\(page)", method: .post, body: filter, authenticated: true)
    }

    func related(relatedID: Int, page: Int) async throws -> Page<Release> {
        try await api.sendEmpty("/related/\(relatedID)/\(page)", apiV2: true, authenticated: true)
    }

    // MARK: - Search

    func searchReleases(query: String, page: Int) async throws -> Page<Release> {
        try await api.send("/search/releases/\(page)", method: .post, body: SearchBody(query: query, searchBy: 0), apiV2: true, authenticated: true)
    }

    func searchProfiles(query: String, page: Int) async throws -> Page<Profile> {
        try await api.send("/search/profiles/\(page)", method: .post, body: SearchBody(query: query, searchBy: 0), authenticated: true)
    }

    func searchCollections(query: String, page: Int) async throws -> Page<Collection> {
        try await api.send("/search/collections/\(page)", method: .post, body: SearchBody(query: query, searchBy: 0), authenticated: true)
    }

    // MARK: - Bookmarks

    func bookmarks(profileID: Int, status: BookmarkStatus, page: Int) async throws -> Page<Release> {
        try await api.sendEmpty("/profile/list/all/\(profileID)/\(status.rawValue)/\(page)", authenticated: true)
    }

    func updateBookmark(releaseID: Int, status: BookmarkStatus) async throws -> APIResponse {
        try await api.sendEmpty("/profile/list/add/\(status.rawValue)/\(releaseID)", authenticated: true)
    }

    func removeBookmark(releaseID: Int, status: BookmarkStatus) async throws -> APIResponse {
        try await api.sendEmpty("/profile/list/delete/\(status.rawValue)/\(releaseID)", authenticated: true)
    }

    // MARK: - Episodes chain: release → dubbers → sources → episodes → video URL

    func dubbers(releaseID: Int) async throws -> EpisodeTypesResponse {
        try await api.sendEmpty("/episode/\(releaseID)", authenticated: true)
    }

    func sources(releaseID: Int, dubberID: Int) async throws -> SourcesResponse {
        try await api.sendEmpty("/episode/\(releaseID)/\(dubberID)", authenticated: true)
    }

    func episodes(releaseID: Int, dubberID: Int, sourceID: Int) async throws -> EpisodesResponse {
        try await api.sendEmpty("/episode/\(releaseID)/\(dubberID)/\(sourceID)", query: ["sort": "1"], authenticated: true)
    }

    func targetEpisode(releaseID: Int, sourceID: Int, position: Int) async throws -> EpisodeResponse {
        try await api.sendEmpty("/episode/target/\(releaseID)/\(sourceID)/\(position)", authenticated: true)
    }

    // MARK: - Episode watch state (POST per AnixAPI 9.x)

    func markEpisode(releaseID: Int, sourceID: Int, position: Int, watched: Bool) async throws -> APIResponse {
        let path = "/episode/\(watched ? "watch" : "unwatch")/\(releaseID)/\(sourceID)/\(position)"
        return try await api.send(path, method: .post, body: Optional<EmptyBody>.none, authenticated: true)
    }

    func markSourceWatched(releaseID: Int, sourceID: Int) async throws -> APIResponse {
        try await api.send("/episode/watch/\(releaseID)/\(sourceID)", method: .post, body: Optional<EmptyBody>.none, authenticated: true)
    }

    func markSourceUnwatched(releaseID: Int, sourceID: Int) async throws -> APIResponse {
        try await api.send("/episode/unwatch/\(releaseID)/\(sourceID)", method: .post, body: Optional<EmptyBody>.none, authenticated: true)
    }

    // MARK: - History

    func addToHistory(releaseID: Int, sourceID: Int, position: Int) async throws -> APIResponse {
        try await api.sendEmpty("/history/add/\(releaseID)/\(sourceID)/\(position)", authenticated: true)
    }

    // MARK: - Comments

    func comments(releaseID: Int, page: Int) async throws -> Page<ReleaseComment> {
        try await api.sendEmpty("/release/comment/all/\(releaseID)/\(page)", query: ["sort": "1"], authenticated: true)
    }

    // MARK: - Notifications

    func notifications(page: Int) async throws -> NotificationsResponse {
        try await api.sendEmpty("/notification/all/\(page)", authenticated: true)
    }

    func readNotifications() async throws -> APIResponse {
        try await api.sendEmpty("/notification/read", authenticated: true)
    }

    // MARK: - Collections

    func collections(page: Int) async throws -> Page<Collection> {
        try await api.sendEmpty("/collection/all/\(page)", authenticated: true)
    }

    func collection(id: Int) async throws -> CollectionDetailResponse {
        try await api.sendEmpty("/collection/\(id)", authenticated: true)
    }

    func collectionReleases(collectionID: Int, page: Int) async throws -> Page<Release> {
        try await api.sendEmpty("/collection/\(collectionID)/releases/\(page)", authenticated: true)
    }

    // MARK: - Feed

    func feed(page: Int) async throws -> Page<Article> {
        try await api.sendEmpty("/feed/latest/all/\(page)", authenticated: true)
    }
}

private struct EmptyBody: Encodable {}
