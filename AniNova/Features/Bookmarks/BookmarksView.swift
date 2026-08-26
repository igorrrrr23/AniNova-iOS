import SwiftUI

struct BookmarksView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var status: BookmarkStatus = .watching; @State private var releases: [Release] = []; @State private var error: String?; @State private var loading = false
    var body: some View { NavigationStack { Group { if loading { ProgressView("Загружаем закладки") } else if let error { ErrorState(message: error) { Task { await load() } } } else if releases.isEmpty { ContentUnavailableView("Список пуст", systemImage: "bookmark") } else { List(releases) { release in NavigationLink(value: release) { Text(release.title) } } } }.navigationTitle("Закладки").toolbar { ToolbarItem(placement: .topBarTrailing) { Picker("Статус", selection: $status) { ForEach(BookmarkStatus.allCases) { Text($0.title).tag($0) } }.pickerStyle(.menu) } }.navigationDestination(for: Release.self) { ReleaseDetailView(release: $0) }.task { await load() }.onChange(of: status) { _ in Task { await load() } } } }
    private func load() async { guard case .authenticated(let profile) = container.auth.state else { return }; loading = true; defer { loading = false }; do { releases = try await container.repository.bookmarks(profileID: profile.id, status: status, page: 0).content; error = nil } catch { self.error = error.localizedDescription } }
}

