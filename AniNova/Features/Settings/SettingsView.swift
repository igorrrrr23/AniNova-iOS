import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var container: AppContainer
    @AppStorage("autoplay") private var autoplay = true
    @AppStorage("preferred.source") private var source = ""

    var body: some View {
        Form {
            Section("Оформление") {
                Picker("Тема", selection: $container.appearance) {
                    Text("Системная").tag("system")
                    Text("Тёмная").tag("dark")
                    Text("Светлая").tag("light")
                    Text("AMOLED").tag("amoled")
                }
            }
            Section("Плеер") {
                Toggle("Автопереход", isOn: $autoplay)
                TextField("Предпочтительный источник", text: $source)
            }
            Section("Данные") {
                Button("Очистить историю", role: .destructive) {
                    container.progress.removeAll()
                }
            }
            Section("Аккаунт") {
                Button("Выйти", role: .destructive) {
                    container.auth.logout()
                }
            }
            Section("О приложении") {
                LabeledContent("Версия", value: "1.0")
                Text("AniNova — неофициальный нативный клиент.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Настройки")
    }
}
