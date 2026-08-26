import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var items: [NotificationItem] = []; @State private var error: String?; @State private var loading = false
    var body: some View { NavigationStack { Group { if loading { ProgressView("Загружаем уведомления") } else if let error { ErrorState(message: error) { Task { await load() } } } else if items.isEmpty { ContentUnavailableView("Нет уведомлений", systemImage: "bell") } else { List(items) { item in Text(item.message ?? "Уведомление") } } }.navigationTitle("Уведомления").toolbar { Button("Прочитано") { Task { try? await container.repository.readNotifications(); await load() } }.disabled(items.isEmpty) }.task { await load() } } }
    private func load() async { loading = true; defer { loading = false }; do { items = try await container.repository.notifications(page: 0).content; error = nil } catch { self.error = error.localizedDescription } }
}

