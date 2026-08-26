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
struct FriendsResponse: Codable { let code: Int; let content: [Profile] }
struct CollectionDetailResponse: Codable { let code: Int; let collection: Collection? }
struct CollectionsResponse: Codable { let code: Int; let content: [Collection] }

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
    let isPlayDisabled: Bool?

    var title: String { titleRu ?? titleOriginal ?? "Без названия" }
    var artworkURL: URL? { URL(string: image ?? poster ?? "") }
    var playable: Bool { !(isPlayDisabled ?? false) }

    static func == (lhs: Release, rhs: Release) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct ReleaseStatus: Codable, Hashable { let id: Int?; let name: String? }
struct ReleaseCategory: Codable, Hashable { let id: Int?; let name: String? }

struct Profile: Codable, Identifiable, Hashable {
    let id: Int
    let login: String?
    let avatar: String?
    let friendCount: Int?
    let watchingCount: Int?
    let completedCount: Int?
    let planCount: Int?
    let holdOnCount: Int?
    let droppedCount: Int?
    let watchDynamics: [WatchDynamic]?

    static func == (lhs: Profile, rhs: Profile) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct WatchDynamic: Codable, Identifiable, Hashable { let count: Int?; let timestamp: Int?; var id: Int { timestamp ?? 0 } }

struct Dubber: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let episodeCount: Int?
    let quality: Int?
    let icon: String?
    let workers: String?
    let isSub: Bool?
    let pinned: Bool?
    let viewCount: Int?

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        episodeCount = try c.decodeIfPresent(Int.self, forKey: .episodeCount)
        quality = try c.decodeIfPresent(Int.self, forKey: .quality)
        icon = try c.decodeIfPresent(String.self, forKey: .icon)
        workers = try c.decodeIfPresent(String.self, forKey: .workers)
        isSub = try c.decodeIfPresent(Bool.self, forKey: .isSub)
        pinned = try c.decodeIfPresent(Bool.self, forKey: .pinned)
        viewCount = try c.decodeIfPresent(Int.self, forKey: .viewCount)
    }

    static func == (lhs: Dubber, rhs: Dubber) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct VideoSource: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let episodeCount: Int?
    let quality: Int?

    static func == (lhs: VideoSource, rhs: VideoSource) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Episode: Codable, Identifiable, Hashable {
    let position: Int
    let name: String?
    let url: String?
    let iframe: Bool?
    let isWatched: Bool?
    let source: SourceReference?
    let addedDate: Int?
    let isFilter: Bool?
    var id: Int { position }

    var iframeOrFalse: Bool { iframe ?? false }
    var isPlayable: Bool {
        guard let url, !url.isEmpty else { return false }
        return !iframeOrFalse
    }
    var videoFormat: VideoFormat {
        guard let url else { return .unknown }
        return VideoFormat.detect(from: url, iframe: iframeOrFalse)
    }

    static func == (lhs: Episode, rhs: Episode) -> Bool { lhs.position == rhs.position }
    func hash(into hasher: inout Hasher) { hasher.combine(position) }
}

struct SourceReference: Codable, Hashable {
    let id: Int?
    let name: String?
    let episodeCount: Int?
    let quality: Int?

    private enum CodingKeys: String, CodingKey {
        case id, name, episodeCount, quality
    }

    init(id: Int?, name: String? = nil, episodeCount: Int? = nil, quality: Int? = nil) {
        self.id = id; self.name = name; self.episodeCount = episodeCount; self.quality = quality
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            self.init(id: intVal)
        } else {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.init(
                id: try c.decodeIfPresent(Int.self, forKey: .id),
                name: try c.decodeIfPresent(String.self, forKey: .name),
                episodeCount: try c.decodeIfPresent(Int.self, forKey: .episodeCount),
                quality: try c.decodeIfPresent(Int.self, forKey: .quality)
            )
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let id { try container.encode(id) } else {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encodeIfPresent(id, forKey: .id)
            try c.encodeIfPresent(name, forKey: .name)
        }
    }
}

enum VideoFormat: Equatable {
    case hls
    case mp4
    case iframe
    case redirect
    case unknown

    static func detect(from urlString: String, iframe: Bool) -> VideoFormat {
        if iframe { return .iframe }
        let lower = urlString.lowercased()
        if lower.contains(".m3u8") || lower.contains("hls") || lower.contains("/manifest") { return .hls }
        if lower.contains(".mp4") || lower.contains("googlevideo") || lower.contains("videoplayback") { return .mp4 }
        if lower.contains("redirect") || lower.contains("location") { return .redirect }
        return .unknown
    }

    var playableByAVPlayer: Bool {
        switch self {
        case .hls, .mp4: return true
        default: return false
        }
    }
}

struct ReleaseComment: Codable, Identifiable, Hashable {
    let id: Int
    let message: String?
    let isSpoiler: Bool?
    let profile: Profile?
    let timestamp: Int?

    static func == (lhs: ReleaseComment, rhs: ReleaseComment) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct NotificationItem: Codable, Identifiable, Hashable {
    let id: Int
    let message: String?
    let timestamp: Int?
    let isRead: Bool?

    static func == (lhs: NotificationItem, rhs: NotificationItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Collection: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let name: String?
    let description: String?
    let itemsCount: Int?

    init(id: Int, title: String?, name: String?, description: String? = nil, itemsCount: Int? = nil) {
        self.id = id; self.title = title; self.name = name; self.description = description; self.itemsCount = itemsCount
    }

    static func == (lhs: Collection, rhs: Collection) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

struct Article: Codable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let content: String?
    let image: String?
    let timestamp: Int?

    static func == (lhs: Article, rhs: Article) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum BookmarkStatus: Int, CaseIterable, Identifiable {
    case watching = 1, planned = 2, completed = 3, onHold = 4, dropped = 5
    var id: Int { rawValue }
    var title: String {
        switch self {
        case .watching: return "Смотрю"
        case .planned: return "Запланировано"
        case .completed: return "Просмотрено"
        case .onHold: return "Отложено"
        case .dropped: return "Брошено"
        }
    }
}
