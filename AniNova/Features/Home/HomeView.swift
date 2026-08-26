import SwiftUI

@MainActor final class HomeViewModel: ObservableObject {
    enum State { case loading, loaded, empty, failed(String) }
    @Published var state: State = .loading
    @Published var releases: [Release] = []
    @Published var selected = HomeCategory.latest
    private let repository: AnixartRepository

    init(repository: AnixartRepository) { self.repository = repository }

    func load() async {
        state = .loading
        do {
            let page = try await repository.releases(page: 0, filter: selected.filter)
            releases = page.content
            state = releases.isEmpty ? .empty : .loaded
        } catch {
            state = .failed(error.localizedDescription)
        }
    }
}

enum HomeCategory: String, CaseIterable, Identifiable {
    case latest = "Последние"
    case airing = "Онгоинги"
    case announced = "Анонсы"
    case finished = "Завершённые"
    case movies = "Фильмы"

    var id: String { rawValue }

    var filter: ReleaseFilter {
        switch self {
        case .latest: return .init(statusId: nil, categoryId: nil, sort: 0)
        case .airing: return .init(statusId: 2, categoryId: nil, sort: 0)
        case .announced: return .init(statusId: 3, categoryId: nil, sort: 0)
        case .finished: return .init(statusId: 1, categoryId: nil, sort: 0)
        case .movies: return .init(statusId: nil, categoryId: 2, sort: 0)
        }
    }
}

struct HomeView: View {
    @EnvironmentObject private var container: AppContainer
    @StateObject private var model: HomeViewModel

    init() { _model = StateObject(wrappedValue: HomeViewModel(repository: AppContainer().repository)) }

    var body: some View {
        NavigationStack {
            Group {
                switch model.state {
                case .loading:
                    ProgressView("Загружаем каталог")
                case .empty:
                    ContentUnavailableView("Ничего не найдено", systemImage: "film")
                case .failed(let message):
                    ErrorState(message: message) { Task { await model.load() } }
                case .loaded:
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 15)], spacing: 20) {
                            ForEach(model.releases) { release in
                                NavigationLink(value: release) {
                                    ReleaseCard(release: release)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("AniNova")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Picker("Раздел", selection: $model.selected) {
                            ForEach(HomeCategory.allCases) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .onChange(of: model.selected) { _, _ in Task { await model.load() } }
            .navigationDestination(for: Release.self) { ReleaseDetailView(release: $0) }
            .task { await model.load() }
        }
    }
}
