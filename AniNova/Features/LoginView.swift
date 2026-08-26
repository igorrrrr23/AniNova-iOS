import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var container: AppContainer
    @State private var login = ""
    @State private var password = ""
    @State private var busy = false
    @State private var error: String?
    var body: some View {
        NavigationStack {
            VStack(spacing: 22) {
                Spacer()
                Image(systemName: "sparkles.tv.fill").font(.system(size: 56)).foregroundStyle(.indigo)
                Text("AniNova").font(.largeTitle.bold())
                Text("Нативный клиент для Anixart").foregroundStyle(.secondary)
                TextField("Логин", text: $login).textInputAutocapitalization(.never).autocorrectionDisabled().textContentType(.username).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                SecureField("Пароль", text: $password).textContentType(.password).padding().background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))
                if let error { Text(error).foregroundStyle(.red).font(.footnote).multilineTextAlignment(.center) }
                Button { Task { await signIn() } } label: { if busy { ProgressView().frame(maxWidth: .infinity) } else { Text("Войти").frame(maxWidth: .infinity) } }.buttonStyle(.borderedProminent).disabled(busy || login.isEmpty || password.isEmpty).accessibilityLabel("Войти в аккаунт Anixart")
                Text("Пароль не сохраняется. Сессионный токен хранится в Keychain.").font(.footnote).foregroundStyle(.secondary).multilineTextAlignment(.center)
                Spacer()
            }.padding(24).navigationBarTitleDisplayMode(.inline)
        }
    }
    private func signIn() async { busy = true; defer { busy = false }; do { try await container.auth.signIn(login: login.trimmingCharacters(in: .whitespacesAndNewlines), password: password) } catch { self.error = error.localizedDescription } }
}

