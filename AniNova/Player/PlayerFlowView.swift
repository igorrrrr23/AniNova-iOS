import SwiftUI
import AVKit

@MainActor final class PlayerFlowViewModel: ObservableObject {
    @Published var dubs: [Dubber]; @Published var sources: [VideoSource] = []; @Published var episodes: [Episode] = []; @Published var selectedDub: Dubber?; @Published var selectedSource: VideoSource?; @Published var selectedEpisode: Episode?; @Published var error: String?
    let release: Release; private let repository: AnixartRepository
    init(release: Release, dubs: [Dubber], repository: AnixartRepository) { self.release = release; self.dubs = dubs; self.repository = repository }
    func chooseDub(_ dub: Dubber) async { selectedDub = dub; selectedSource = nil; episodes = []; do { sources = try await repository.sources(releaseID: release.id, dubberID: dub.id).sources } catch { self.error = error.localizedDescription } }
    func chooseSource(_ source: VideoSource) async { selectedSource = source; guard let dub = selectedDub else { return }; do { episodes = try await repository.episodes(releaseID: release.id, dubberID: dub.id, sourceID: source.id).episodes; selectedEpisode = episodes.first } catch { self.error = error.localizedDescription } }
}

struct PlayerFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: PlayerFlowViewModel
    init(release: Release, dubs: [Dubber]) { _model = StateObject(wrappedValue: PlayerFlowViewModel(release: release, dubs: dubs, repository: AppContainer().repository)) }
    var body: some View { NavigationStack { Group { if let episode = model.selectedEpisode, let urlString = episode.url, !episode.iframeOrFalse, let url = URL(string: urlString) { NativePlayerView(url: url, releaseID: model.release.id, episode: episode) } else { List { Section("Озвучка") { ForEach(model.dubs) { dub in Button(dub.name ?? "Озвучка") { Task { await model.chooseDub(dub) } } } }; if !model.sources.isEmpty { Section("Источник") { ForEach(model.sources) { source in Button(source.name ?? "Источник") { Task { await model.chooseSource(source) } } } }; if !model.episodes.isEmpty { Section("Серия") { ForEach(model.episodes) { episode in Button("Серия \(episode.position) \(episode.name ?? "")") { model.selectedEpisode = episode } } } }; if let error = model.error { Text(error).foregroundStyle(.red) } } } }.navigationTitle(model.release.title).toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } } } }.task { if let first = model.dubs.first { await model.chooseDub(first) } } }
}
extension Episode { var iframeOrFalse: Bool { iframe ?? false } }

struct NativePlayerView: View {
    let url: URL; let releaseID: Int; let episode: Episode
    @EnvironmentObject private var container: AppContainer
    @StateObject private var coordinator = PlayerCoordinator()
    var body: some View { VideoPlayerController(player: coordinator.player).ignoresSafeArea().task { coordinator.play(url: url, releaseID: releaseID, episode: episode, store: container.progress) }.onDisappear { coordinator.persist() } }
}

@MainActor final class PlayerCoordinator: NSObject, ObservableObject {
    let player = AVPlayer(); private var observer: Any?; private var context: (Int, Episode, ProgressStore)?
    func play(url: URL, releaseID: Int, episode: Episode, store: ProgressStore) { persist(); context = (releaseID, episode, store); player.replaceCurrentItem(with: AVPlayerItem(url: url)); observer = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 10, preferredTimescale: 600), queue: .main) { [weak self] _ in self?.persist() }; player.play() }
    func persist() { guard let context, let item = player.currentItem else { return }; let duration = item.duration.seconds; let seconds = player.currentTime().seconds; guard seconds.isFinite, duration.isFinite, duration > 0, let sourceID = context.1.source?.id else { return }; context.2.save(.init(releaseID: context.0, episodePosition: context.1.position, sourceID: sourceID, seconds: seconds, duration: duration, updatedAt: .now)) }
    deinit { if let observer { player.removeTimeObserver(observer) } }
}

struct VideoPlayerController: UIViewControllerRepresentable {
    let player: AVPlayer
    func makeUIViewController(context: Context) -> AVPlayerViewController { let controller = AVPlayerViewController(); controller.player = player; controller.allowsPictureInPicturePlayback = true; controller.canStartPictureInPictureAutomaticallyFromInline = true; return controller }
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) { controller.player = player }
}

