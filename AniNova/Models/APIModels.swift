import Foundation

struct APIResponse: Codable { let code: Int }
struct Page<Response: Codable>: Codable { let code: Int; let content: [Response]; let totalCount: Int?; let totalPageCount: Int?; let currentPage: Int? }
struct LoginResponse: Codable { let code: Int; let profile: Profile?; let profileToken: ProfileToken? }
struct ProfileToken: Codable { let token: String }
struct ReleaseResponse: Codable { let code: Int; let release: Release? }
struct ProfileResponse: Codable { let code: Int; let profile: Profile?; let isMyProfile: Bool? }
struct EpisodeTypesResponse: Codable { let code: Int; let types: [Dubber] }
struct SourcesResponse: Codable { let code: Int; let sources: [VideoSource] }
struct EpisodesResponse: Codable { let code: Int; let episodes: [Episode] }
struct EpisodeResponse: Codable { let code: Int; let episode: Episode? }
struct NotificationsResponse: Codable { let code: Int; let content: [NotificationItem] }

struct Release: Codable, Identifiable, Hashable {
    let id: Int
    let image: String?
    let poster: String?
    let titleRu: String?
    let titleOriginal: String?
    let titleAlt: String?
    let year: String?
    let genres: String?
    let description: String?
    let grade: Double?
    let status: ReleaseStatus?
    let category: ReleaseCategory?
    let episodesReleased: Int?
    let episodesTotal: Int?
    let screenshots: [String]?
    let screenshotImages: [String]?
    let relatedReleases: [Release]?
    let recommendedReleases: [Release]?
    let profileListStatus: Int?
    let isFavorite: Bool?
    let lastViewEpisode: Episode?
    var title: String { titleRu ?? titleOriginal ?? "Без названия" }
    var artworkURL: URL? { URL(string: image ?? "") }
}

struct ReleaseStatus: Codable, Hashable { let id: Int?; let name: String? }
struct ReleaseCategory: Codable, Hashable { let id: Int?; let name: String? }
struct Profile: Codable, Identifiable, Hashable { let id: Int; let login: String?; let avatar: String?; let friendCount: Int?; let watchingCount: Int?; let completedCount: Int?; let planCount: Int?; let holdOnCount: Int?; let droppedCount: Int?; let watchDynamics: [WatchDynamic]? }
struct WatchDynamic: Codable, Hashable { let count: Int?; let timestamp: Int? }
struct Dubber: Codable, Identifiable, Hashable { let id: Int; let name: String?; let episodeCount: Int?; let quality: Int? }
struct VideoSource: Codable, Identifiable, Hashable { let id: Int; let name: String?; let episodeCount: Int?; let quality: Int? }
struct Episode: Codable, Identifiable, Hashable { let position: Int; let name: String?; let url: String?; let iframe: Bool?; let isWatched: Bool?; let source: SourceReference?; var id: Int { position } }
struct SourceReference: Codable, Hashable { let id: Int? }
struct ReleaseComment: Codable, Identifiable, Hashable { let id: Int; let message: String?; let isSpoiler: Bool?; let profile: Profile?; let timestamp: Int? }
struct NotificationItem: Codable, Identifiable, Hashable { let id: Int; let message: String?; let timestamp: Int?; let isRead: Bool? }

enum BookmarkStatus: Int, CaseIterable, Identifiable { case watching = 1, planned = 2, completed = 3, onHold = 4, dropped = 5; var id: Int { rawValue }; var title: String { switch self { case .watching: return "Смотрю"; case .planned: return "Запланировано"; case .completed: return "Просмотрено"; case .onHold: return "Отложено"; case .dropped: return "Брошено" } } }

