import SwiftUI

struct RootView: View {
    @EnvironmentObject private var container: AppContainer

    var body: some View {
        Group {
            switch container.auth.state {
            case .restoring: ProgressView("Восстанавливаем сессию")
            case .unauthenticated: LoginView()
            case .authenticated: MainTabView()
            }
        }
        .preferredColorScheme(colorScheme)
        .task { await container.auth.restore() }
    }

    private var colorScheme: ColorScheme? {
        switch container.appearance {
        case "dark", "amoled": return .dark
        case "light": return .light
        default: return nil
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView().tabItem { Label("Главная", systemImage: "house.fill") }
            SearchView().tabItem { Label("Поиск", systemImage: "magnifyingglass") }
            BookmarksView().tabItem { Label("Закладки", systemImage: "bookmark.fill") }
            NotificationsView().tabItem { Label("Уведомления", systemImage: "bell.fill") }
            ProfileView().tabItem { Label("Профиль", systemImage: "person.crop.circle") }
        }
        .tint(.indigo)
    }
}
