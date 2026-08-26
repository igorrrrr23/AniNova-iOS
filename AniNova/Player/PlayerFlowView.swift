import SwiftUI
import AVKit

@MainActor final class PlayerFlowViewModel: ObservableObject {
    @Published var dubs: [Dubber]
    @Published var sources: [VideoSource] = []
    @Published var episodes: [Episode] = []
    @Published var selectedDub: Dubber?
    @Published var selectedSource: VideoSource?
    @Published var selectedEpisode: Episode?
    @Published var error: String?
    @Published var showSelector = true
    let release: Release
    private let repository: AnixartRepository

    init(release: Release, dubs: [Dubber], repository: AnixartRepository) {
        self.release = release
        self.dubs = dubs
        self.repository = repository
    }

    var currentEpisodeIndex: Int? {
        guard let sel = selectedEpisode else { return nil }
        return episodes.firstIndex { $0.position == sel.position }
    }

    var nextEpisode: Episode? {
        guard let idx = currentEpisodeIndex, idx + 1 < episodes.count else { return nil }
        return episodes[idx + 1]
    }

    var previousEpisode: Episode? {
        guard let idx = currentEpisodeIndex, idx - 1 >= 0 else { return nil }
        return episodes[idx - 1]
    }

    func chooseDub(_ dub: Dubber) async {
        selectedDub = dub
        selectedSource = nil
        episodes = []
        selectedEpisode = nil
        do {
            sources = try await repository.sources(releaseID: release.id, dubberID: dub.id).sources
            if let first = sources.first { await chooseSource(first) }
        } catch { self.error = error.localizedDescription }
    }

    func chooseSource(_ source: VideoSource) async {
        selectedSource = source
        guard let dub = selectedDub else { return }
        do {
            let response = try await repository.episodes(releaseID: release.id, dubberID: dub.id, sourceID: source.id)
            episodes = response.episodes.sorted { $0.position < $1.position }
            if let playable = episodes.first(where: { $0.isPlayable }) {
                selectEpisode(playable)
            }
        } catch { self.error = error.localizedDescription }
    }

    func selectEpisode(_ episode: Episode) {
        selectedEpisode = episode
        showSelector = false
    }

    func playNext() {
        guard let idx = currentEpisodeIndex else { return }
        let remaining = Array(episodes.dropFirst(idx + 1))
        if let next = remaining.first(where: { $0.isPlayable }) { selectEpisode(next) }
    }

    func playPrevious() {
        guard let idx = currentEpisodeIndex else { return }
        let preceding = Array(episodes.prefix(idx))
        if let prev = preceding.last(where: { $0.isPlayable }) { selectEpisode(prev) }
    }

    func playableURL(for episode: Episode) -> URL? {
        guard let urlString = episode.url, !urlString.isEmpty, !episode.iframeOrFalse else { return nil }
        return URL(string: urlString)
    }
}

struct PlayerFlowView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model: PlayerFlowViewModel

    init(release: Release, dubs: [Dubber]) {
        _model = StateObject(wrappedValue: PlayerFlowViewModel(
            release: release, dubs: dubs, repository: AppContainer().repository
        ))
    }

    var body: some View {
        NavigationStack {
            Group {
                if model.showSelector { selectorView }
                else if let episode = model.selectedEpisode,
                        let url = model.playableURL(for: episode) {
                    playerView(url: url, episode: episode)
                } else if let episode = model.selectedEpisode, episode.iframeOrFalse {
                    VStack(spacing: 16) {
                        Image(systemName: "lock.slash").font(.system(size: 48)).foregroundStyle(.secondary)
                        Text("Источник не поддерживается").font(.headline)
                        Text("Этот эпизод использует встраиваемый плеер (iframe), несовместимый с нативным AVPlayer.")
                            .multilineTextAlignment(.center).foregroundStyle(.secondary).font(.subheadline).padding(.horizontal, 32)
                        if let url = episode.url {
                            Button("Копировать ссылку") { UIPasteboard.general.string = url }.buttonStyle(.bordered)
                        }
                        Button("Выбрать другой источник") { model.showSelector = true }.buttonStyle(.borderedProminent)
                    }.padding()
                } else {
                    ContentUnavailableView("Выберите озвучку и источник", systemImage: "play.rectangle")
                }
            }
            .navigationTitle(model.release.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { Button("Выбор") { model.showSelector = true } }
                ToolbarItem(placement: .topBarTrailing) { Button("Готово") { dismiss() } }
            }
            .task { if let first = model.dubs.first { await model.chooseDub(first) } }
        }
    }

    private var selectorView: some View {
        List {
            Section("Озвучка (\(model.dubs.count))") {
                ForEach(model.dubs) { dub in
                    Button { Task { await model.chooseDub(dub) } } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(dub.name ?? "Озвучка")
                                if let w = dub.workers, !w.isEmpty {
                                    Text(w).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                                }
                            }
                            Spacer()
                            if dub.id == model.selectedDub?.id { Image(systemName: "checkmark").foregroundStyle(.indigo) }
                        }
                    }
                }
            }
            if !model.sources.isEmpty {
                Section("Источник (\(model.sources.count))") {
                    ForEach(model.sources) { source in
                        Button { Task { await model.chooseSource(source) } } label: {
                            HStack {
                                Text(source.name ?? "Источник")
                                if let q = source.quality { Text("· \(q)p").foregroundStyle(.secondary) }
                                Spacer()
                                if source.id == model.selectedSource?.id { Image(systemName: "checkmark").foregroundStyle(.indigo) }
                            }
                        }
                    }
                }
            }
            if !model.episodes.isEmpty {
                Section("Эпизоды (\(model.episodes.count))") {
                    ForEach(model.episodes) { ep in
                        Button { model.selectEpisode(ep) } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Эпизод \(ep.position)").font(.subheadline)
                                    if let name = ep.name, !name.isEmpty { Text(name).font(.caption).foregroundStyle(.secondary) }
                                }
                                Spacer()
                                if ep.isWatched == true { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green).font(.caption) }
                                if ep.iframeOrFalse { Image(systemName: "lock").foregroundStyle(.orange).font(.caption) }
                                else if ep.isPlayable {
                                    Text(ep.videoFormat == .hls ? "HLS" : ep.videoFormat == .mp4 ? "MP4" : "")
                                        .font(.caption2).foregroundStyle(.secondary)
                                        .padding(.horizontal, 6).padding(.vertical, 2)
                                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 4))
                                }
                            }
                        }.disabled(!ep.isPlayable)
                    }
                }
            }
            if let error = model.error { Section { Text(error).foregroundStyle(.red) } }
        }
    }

    private func playerView(url: URL, episode: Episode) -> some View {
        NativePlayerView(
            url: url, releaseID: model.release.id, episode: episode,
            episodes: model.episodes,
            hasNext: model.nextEpisode != nil, hasPrevious: model.previousEpisode != nil,
            onNext: { model.playNext() }, onPrevious: { model.playPrevious() },
            onSourceChange: { model.showSelector = true }
        ).ignoresSafeArea()
    }
}

struct NativePlayerView: UIViewControllerRepresentable {
    let url: URL
    let releaseID: Int
    let episode: Episode
    let episodes: [Episode]
    var hasNext: Bool = false
    var hasPrevious: Bool = false
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onSourceChange: (() -> Void)?

    @EnvironmentObject private var container: AppContainer
    @StateObject private var coordinator = PlayerCoordinator()

    func makeUIViewController(context: Context) -> PlayerCoordinatorViewController {
        let vc = PlayerCoordinatorViewController()
        vc.coordinator = coordinator
        vc.onNext = onNext
        vc.onPrevious = onPrevious
        vc.onSourceChange = onSourceChange
        vc.hasNext = hasNext
        vc.hasPrevious = hasPrevious
        vc.setup(
            url: url, releaseID: releaseID, episode: episode, episodes: episodes,
            store: container.progress, repository: container.repository
        )
        return vc
    }

    func updateUIViewController(_ vc: PlayerCoordinatorViewController, context: Context) {
        vc.hasNext = hasNext
        vc.hasPrevious = hasPrevious
    }
}

final class PlayerCoordinatorViewController: UIViewController, AVPlayerViewControllerDelegate {
    var coordinator: PlayerCoordinator!
    var onNext: (() -> Void)?
    var onPrevious: (() -> Void)?
    var onSourceChange: (() -> Void)?
    var hasNext: Bool = false
    var hasPrevious: Bool = false

    private var playerVC: AVPlayerViewController!
    private var thumbnailGenerator: AVAssetImageGenerator?
    private var thumbnailView: ThumbnailPreviewView?
    private var timeObserver: Any?
    private var url: URL!
    private var releaseID: Int!
    private var episode: Episode!
    private var episodes: [Episode]!
    private var store: ProgressStore!
    private var repository: AnixartRepository!
    private var didSetup = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        playerVC = AVPlayerViewController()
        playerVC.delegate = self
        playerVC.allowsPictureInPicturePlayback = true
        playerVC.canStartPictureInPictureAutomaticallyFromInline = true
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playerVC.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerVC.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            playerVC.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            playerVC.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        playerVC.didMove(toParent: self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didSetup else { return }
        didSetup = true
        startPlayback()
    }

    func setup(url: URL, releaseID: Int, episode: Episode, episodes: [Episode], store: ProgressStore, repository: AnixartRepository) {
        self.url = url
        self.releaseID = releaseID
        self.episode = episode
        self.episodes = episodes
        self.store = store
        self.repository = repository
        if isViewLoaded { startPlayback() }
    }

    private func startPlayback() {
        guard let url else { return }
        coordinator?.play(url: url, releaseID: releaseID, episode: episode, store: store, repository: repository)
        playerVC.player = coordinator?.player

        thumbnailGenerator = coordinator?.player.currentItem?.asset
            .flatMap { $0 as? AVURLAsset }
            .map { AVAssetImageGenerator(asset: $0) }
        thumbnailGenerator?.appliesPreferredTrackTransform = true
        thumbnailGenerator?.maximumSize = CGSize(width: 160, height: 90)
        thumbnailGenerator?.requestsTimeOffsetsOutsideBounds = false

        timeObserver = coordinator?.player.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 1, preferredTimescale: 600), queue: .main
        ) { [weak self] _ in
            self?.coordinator?.persist()
        }

        setupKeyboardShortcuts()
        setupThumbnailPreview()
    }

    private func setupKeyboardShortcuts() {
        let commaKey = UIKeyCommand(title: "Previous Frame", action: #selector(stepBackward), input: ",", modifierFlags: [])
        let periodKey = UIKeyCommand(title: "Next Frame", action: #selector(stepForward), input: ".", modifierFlags: [])
        let leftKey = UIKeyCommand(title: "Rewind 5s", action: #selector(rewind), input: UIKeyCommand.inputLeftArrow, modifierFlags: [])
        let rightKey = UIKeyCommand(title: "Forward 5s", action: #selector(forward), input: UIKeyCommand.inputRightArrow, modifierFlags: [])
        let spaceKey = UIKeyCommand(title: "Play/Pause", action: #selector(togglePlayPause), input: " ", modifierFlags: [])

        addKeyCommand(commaKey)
        addKeyCommand(periodKey)
        addKeyCommand(leftKey)
        addKeyCommand(rightKey)
        addKeyCommand(spaceKey)

        if hasNext {
            addKeyCommand(UIKeyCommand(title: "Next Episode", action: #selector(goNext), input: UIKeyCommand.inputRightArrow, modifierFlags: .command))
        }
        if hasPrevious {
            addKeyCommand(UIKeyCommand(title: "Previous Episode", action: #selector(goPrevious), input: UIKeyCommand.inputLeftArrow, modifierFlags: .command))
        }
    }

    @objc private func stepBackward() {
        guard let player = coordinator?.player else { return }
        player.pause()
        let step = CMTime(value: 1, timescale: 30)
        let target = CMTimeMaximum(CMTimeSubtract(player.currentTime(), step), .zero)
        player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    @objc private func stepForward() {
        guard let player = coordinator?.player else { return }
        player.pause()
        let step = CMTime(value: 1, timescale: 30)
        let target = CMTimeAdd(player.currentTime(), step)
        if let item = player.currentItem {
            let maxTime = item.duration
            if CMTimeCompare(target, maxTime) < 0 {
                player.seek(to: target, toleranceBefore: .zero, toleranceAfter: .zero)
            }
        }
    }

    @objc private func rewind() {
        guard let player = coordinator?.player else { return }
        let target = CMTimeMaximum(CMTimeSubtract(player.currentTime(), CMTime(seconds: 5, preferredTimescale: 600)), .zero)
        player.seek(to: target)
    }
    @objc private func forward() {
        guard let player = coordinator?.player else { return }
        let target = CMTimeAdd(player.currentTime(), CMTime(seconds: 5, preferredTimescale: 600))
        if let item = player.currentItem, CMTimeCompare(target, item.duration) < 0 {
            player.seek(to: target)
        }
    }
    @objc private func togglePlayPause() {
        guard let player = coordinator?.player else { return }
        player.timeControlStatus == .playing ? player.pause() : player.play()
    }
    @objc private func goNext() { onNext?() }
    @objc private func goPrevious() { onPrevious?() }

    private func setupThumbnailPreview() {
        let thumbView = ThumbnailPreviewView()
        thumbView.isHidden = true
        thumbView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(thumbView)
        NSLayoutConstraint.activate([
            thumbView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            thumbView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -80)
        ])
        self.thumbnailView = thumbView
    }

    func showThumbnail(at time: CMTime) {
        guard let generator = thumbnailGenerator else { return }
        let times = [NSValue(time: time)]
        generator.generateCGImagesAsynchronously(forTimes: times) { [weak self] _, cgImage, _, _, _ in
            guard let cgImage else { return }
            Task { @MainActor in
                let image = UIImage(cgImage: cgImage)
                self?.thumbnailView?.update(image: image, time: time)
                self?.thumbnailView?.isHidden = false
            }
        }
    }

    func hideThumbnail() {
        thumbnailView?.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        coordinator?.stopAndPersist()
        if let obs = timeObserver, let player = coordinator?.player {
            player.removeTimeObserver(obs)
        }
    }
}

final class ThumbnailPreviewView: UIView {
    private let imageView = UIImageView()
    private let timeLabel = UILabel()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 8
        clipsToBounds = true
        addSubview(blur)
        addSubview(imageView)
        addSubview(timeLabel)
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        timeLabel.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
    }

    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        blur.frame = bounds
        imageView.frame = bounds
        timeLabel.frame = CGRect(x: 0, y: bounds.height - 22, width: bounds.width, height: 22)
    }

    func update(image: UIImage, time: CMTime) {
        imageView.image = image
        let total = Int(time.seconds)
        let h = total / 3600, m = (total % 3600) / 60, s = total % 60
        timeLabel.text = h > 0 ? String(format: "%d:%02d:%02d", h, m, s) : String(format: "%d:%02d", m, s)
        frame.size = CGSize(width: 160, height: 100)
    }
}

@MainActor final class PlayerCoordinator: NSObject, ObservableObject {
    let player = AVPlayer()
    private var context: (releaseID: Int, episode: Episode, store: ProgressStore, repository: AnixartRepository)?

    func play(url: URL, releaseID: Int, episode: Episode, store: ProgressStore, repository: AnixartRepository) {
        stopAndPersist()
        context = (releaseID, episode, store, repository)

        let item = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: item)

        if let saved = store.progress(for: releaseID, episodePosition: episode.position, sourceID: episode.source?.id ?? 0),
           saved.seconds > 5, saved.seconds < saved.duration - 3 {
            player.seek(to: CMTime(seconds: saved.seconds, preferredTimescale: 600))
        }

        player.play()

        Task { @MainActor in
            try? await repository.addToHistory(releaseID: releaseID, sourceID: episode.source?.id ?? 0, position: episode.position)
        }
    }

    func persist() {
        guard let ctx = context, let item = player.currentItem else { return }
        let duration = item.duration.seconds
        let seconds = player.currentTime().seconds
        guard seconds.isFinite, duration.isFinite, duration > 10 else { return }
        ctx.store.save(.init(
            releaseID: ctx.releaseID, episodePosition: ctx.episode.position,
            sourceID: ctx.episode.source?.id ?? 0,
            seconds: seconds, duration: duration, updatedAt: .now
        ))
    }

    func stopAndPersist() {
        persist()
        player.pause()
        if let ctx = context, let item = player.currentItem {
            let seconds = player.currentTime().seconds
            let duration = item.duration.seconds
            if seconds.isFinite, duration.isFinite, duration > 10, seconds > duration * 0.9 {
                Task { @MainActor in
                    try? await ctx.repository.markEpisode(releaseID: ctx.releaseID, sourceID: ctx.episode.source?.id ?? 0, position: ctx.episode.position, watched: true)
                }
            }
        }
        context = nil
    }
}
