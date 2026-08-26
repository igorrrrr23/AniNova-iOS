import SwiftUI

struct ReleaseCard: View {
    let release: Release

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            CachedArtwork(url: release.artworkURL)
                .frame(height: 205)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            Text(release.title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
            HStack(spacing: 5) {
                if let grade = release.grade {
                    Label(String(format: "%.1f", grade), systemImage: "star.fill")
                        .foregroundStyle(.yellow)
                }
                if let year = release.year {
                    Text(year)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(release.title)
    }
}

struct CachedArtwork: View {
    let url: URL?

    var body: some View {
        AsyncImage(url: url, transaction: .init(animation: .easeInOut)) { phase in
            switch phase {
            case .success(let image):
                image.resizable().scaledToFill()
            case .failure:
                fallback
            case .empty:
                ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
            @unknown default:
                fallback
            }
        }
        .background(Color.secondary.opacity(0.15))
        .clipped()
        .accessibilityHidden(true)
    }

    private var fallback: some View {
        Image(systemName: "film.stack")
            .font(.largeTitle)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ErrorState: View {
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView(
            "Не удалось загрузить данные",
            systemImage: "wifi.exclamationmark",
            description: Text(message)
        )
        .overlay(alignment: .bottom) {
            Button("Повторить", action: retry)
                .buttonStyle(.borderedProminent)
        }
    }
}
