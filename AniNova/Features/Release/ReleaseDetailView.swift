import SwiftUI

@MainActor final class ReleaseDetailViewModel: ObservableObject {
    @Published var release: Release
    @Published var comments: [ReleaseComment] = []
    @Published var dubs: [Dubber] = []
    @Published var error: String?
    private let repository: AnixartRepository

    init(release: Release, repository: AnixartRepository) {
        self.release = release
        self.repository = repository
    }

    func load() async {
        do {
            async let details = repository.release(id: release.id)
            async let comments = repository.comments(releaseID: release.id, page: 0)
            async let dubs = repository.dubbers(releaseID: release.id)
            if let fetched = try await details.release { release = fetched }
            self.comments = try await comments.content
            self.dubs = try await dubs.types
        } catch {
            self.error = error.localizedDescription
        }
    }

    func changeBookmark(_ status: BookmarkStatus?) async {
        do {
            if let status {
                _ = try await repository.updateBookmark(releaseID: release.id, status: status)
            } else if let current = BookmarkStatus(rawValue: release.profileListStatus ?? 0) {
                _ = try await repository.removeBookmark(releaseID: release.id, status: current)
            }
        } catch {
            self.error = error.localizedDescription
        }
    }
}

struct ReleaseDetailView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var model: ReleaseDetailViewModel
    @State private var showPlayer = false

    init(release: Release) {
        _model = StateObject(wrappedValue: ReleaseDetailViewModel(release: release, repository: AppContainer().repository))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CachedArtwork(url: model.release.artworkURL)
                    .frame(height: 310)
                    .clipShape(RoundedRectangle(cornerRadius: 22))

                Text(model.release.title)
                    .font(.title2.bold())

                if let alt = model.release.titleAlt {
                    Text(alt).foregroundStyle(.secondary)
                }

                HStack {
                    if let grade = model.release.grade {
                        Label(String(format: "%.1f", grade), systemImage: "star.fill")
                    }
                    Text(model.release.status?.name ?? "")
                }
                .foregroundStyle(.yellow)

                if let genres = model.release.genres {
                    Text(genres).font(.subheadline).foregroundStyle(.secondary)
                }

                if let description = model.release.description {
                    Text(description)
                }

                HStack {
                    Button("Смотреть", systemImage: "play.fill") { showPlayer = true }
                        .buttonStyle(.borderedProminent)
                    Menu("Закладка") {
                        ForEach(BookmarkStatus.allCases) { status in
                            Button(status.title) { Task { await model.changeBookmark(status) } }
                        }
                        Button("Убрать", role: .destructive) { Task { await model.changeBookmark(nil) } }
                    }
                    .buttonStyle(.bordered)
                }

                if !model.release.screenshotImagesOrScreenshots.isEmpty {
                    Text("Скриншоты").font(.headline)
                    ScrollView(.horizontal) {
                        LazyHStack {
                            ForEach(model.release.screenshotImagesOrScreenshots, id: \.self) { image in
                                CachedArtwork(url: URL(string: image))
                                    .frame(width: 210, height: 125)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                }

                if !model.comments.isEmpty {
                    Text("Комментарии").font(.headline)
                    ForEach(model.comments) { comment in
                        VStack(alignment: .leading) {
                            Text(comment.profile?.login ?? "Пользователь").font(.caption.bold())
                            Text(comment.message ?? "")
                        }
                        .padding()
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
                    }
                }

                if let error = model.error {
                    Text(error).foregroundStyle(.red)
                }
            }
            .padding()
        }
        .navigationTitle("Релиз")
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .sheet(isPresented: $showPlayer) {
            PlayerFlowView(release: model.release, dubs: model.dubs)
        }
    }
}

extension Release {
    var screenshotImagesOrScreenshots: [String] {
        (screenshotImages ?? []).isEmpty ? (screenshots ?? []) : (screenshotImages ?? [])
    }
}
