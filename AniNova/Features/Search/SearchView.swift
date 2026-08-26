import SwiftUI

@MainActor final class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var releases: [Release] = []
    @Published var profiles: [Profile] = []
    @Published var error: String?
    @Published var loading = false
    private let repository: AnixartRepository
    private var task: Task<Void, Never>?

    init(repository: AnixartRepository) { self.repository = repository }

    func changed() {
        task?.cancel()
        guard query.count > 1 else { releases = []; profiles = []; return }
        task = Task {
            try? await Task.sleep(for: .milliseconds(350))
            guard !Task.isCancelled else { return }
            await search()
        }
    }

    func search() async {
        loading = true
        defer { loading = false }
        do {
            async let r = repository.searchReleases(query: query, page: 0)
            async let p = repository.searchProfiles(query: query, page: 0)
            releases = try await r.content
            profiles = try await p.content
            SearchHistory.save(query)
        } catch { self.error = error.localizedDescription }
    }
}

enum SearchHistory {
    static let key = "search.history"
    static var values: [String] { UserDefaults.standard.stringArray(forKey: key) ?? [] }
    static func save(_ query: String) {
        UserDefaults.standard.set(([query] + values.filter { $0 != query }).prefix(20), forKey: key)
    }
    static func clear() { UserDefaults.standard.removeObject(forKey: key) }
}

struct SearchView: View {
    @StateObject private var model = SearchViewModel(repository: AppContainer().repository)

    var body: some View {
        NavigationStack {
            List {
                if model.query.isEmpty {
                    Section("Недавние запросы") {
                        ForEach(SearchHistory.values, id: \.self) { Text($0) }
                        if !SearchHistory.values.isEmpty {
                            Button("Очистить историю", role: .destructive) { SearchHistory.clear() }
                        }
                    }
                } else {
                    if model.loading { ProgressView() }
                    if let error = model.error { Text(error).foregroundStyle(.red) }
                    Section("Аниме") {
                        ForEach(model.releases) { release in
                            NavigationLink(value: release) {
                                HStack {
                                    CachedArtwork(url: release.artworkURL)
                                        .frame(width: 54, height: 76)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                    VStack(alignment: .leading) {
                                        Text(release.title)
                                        Text(release.year ?? "")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    Section("Профили") {
                        ForEach(model.profiles) { profile in
                            Text(profile.login ?? "Профиль")
                        }
                    }
                }
            }
            .navigationTitle("Поиск")
            .searchable(text: $model.query, prompt: "Аниме, профиль или коллекция")
            .onChange(of: model.query) { _, _ in model.changed() }
            .navigationDestination(for: Release.self) { ReleaseDetailView(release: $0) }
        }
    }
}
