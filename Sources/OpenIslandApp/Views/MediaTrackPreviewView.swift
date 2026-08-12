import SwiftUI

struct MediaTrackPreviewView: View {
    let snapshot: MediaPlaybackSnapshot

    var body: some View {
        HStack(spacing: MediaTrackPreviewPolicy.contentSpacing) {
            artwork
                .frame(
                    width: MediaTrackPreviewPolicy.artworkSize,
                    height: MediaTrackPreviewPolicy.artworkSize
                )

            VStack(alignment: .leading, spacing: MediaTrackPreviewPolicy.textSpacing) {
                Text(snapshot.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(snapshot.artist)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: MediaTrackPreviewPolicy.contentHeight)
        .frame(
            maxWidth: MediaTrackPreviewPolicy.maximumContentWidth,
            alignment: .leading
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var artwork: some View {
        AsyncImage(url: snapshot.artworkURL) { phase in
            switch phase {
            case let .success(image):
                image
                    .resizable()
                    .scaledToFill()
            default:
                ZStack {
                    LinearGradient(
                        colors: [.gray.opacity(0.62), .black],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: "music.note")
                        .font(.title2)
                        .foregroundStyle(.white)
                }
            }
        }
        .clipShape(
            .rect(
                cornerRadius: MediaTrackPreviewPolicy.artworkCornerRadius,
                style: .continuous
            )
        )
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        if snapshot.artist.isEmpty {
            return "Now playing \(snapshot.title)"
        }
        return "Now playing \(snapshot.title) by \(snapshot.artist)"
    }
}
