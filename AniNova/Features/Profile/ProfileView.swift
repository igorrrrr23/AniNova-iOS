import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var details: Profile?; @State private var error: String?
    var body: some View { NavigationStack { Group { if let profile = details { List { Section { HStack { CachedArtwork(url: URL(string: profile.avatar ?? "")).frame(width: 70, height: 70).clipShape(Circle()); VStack(alignment: .leading) { Text(profile.login ?? "Профиль").font(.title3.bold()); Text("Anixart") .foregroundStyle(.secondary) } } }; Section("Статистика") { LabeledContent("Смотрю", value: "\(profile.watchingCount ?? 0)"); LabeledContent("Просмотрено", value: "\(profile.completedCount ?? 0)"); LabeledContent("Запланировано", value: "\(profile.planCount ?? 0)"); LabeledContent("Друзья", value: "\(profile.friendCount ?? 0)") }; Section { NavigationLink("Настройки") { SettingsView() } } } } else if let error { ErrorState(message: error) { Task { await load() } } } else { ProgressView("Загружаем профиль") } }.navigationTitle("Профиль").task { await load() } } }
    private func load() async { do { guard case .authenticated(let current) = container.auth.state else { return }; details = try await container.repository.profile(id: current.id).profile } catch { self.error = error.localizedDescription } }
}

