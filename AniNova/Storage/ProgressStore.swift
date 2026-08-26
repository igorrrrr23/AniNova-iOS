import Foundation

struct WatchProgress: Codable, Identifiable, Hashable { let releaseID: Int; let episodePosition: Int; let sourceID: Int; let seconds: Double; let duration: Double; let updatedAt: Date; var id: String { "\(releaseID)_\(episodePosition)_\(sourceID)" } }

final class ProgressStore {
    private let key = "watch.progress.v1"
    func all() -> [WatchProgress] { (try? JSONDecoder().decode([WatchProgress].self, from: UserDefaults.standard.data(forKey: key) ?? Data())) ?? [] }
    func save(_ progress: WatchProgress) { var entries = all().filter { $0.id != progress.id }; entries.append(progress); UserDefaults.standard.set(try? JSONEncoder().encode(entries.sorted { $0.updatedAt > $1.updatedAt }), forKey: key) }
    func removeAll() { UserDefaults.standard.removeObject(forKey: key) }
    
    func progress(for releaseID: Int, episodePosition: Int, sourceID: Int) -> WatchProgress? {
        all().first { $0.releaseID == releaseID && $0.episodePosition == episodePosition && $0.sourceID == sourceID }
    }
}
