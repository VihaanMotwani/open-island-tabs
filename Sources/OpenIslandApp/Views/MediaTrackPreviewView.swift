import SwiftUI

struct MediaTrackPreviewView: View {
    let snapshot: MediaPlaybackSnapshot

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHighlighted = false

    var body: some View {
        HStack(spacing: 10) {
            artwork
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(snapshot.title)
                    .font(.headline)
                    .foregroundStyle(ExpandedNotchVisualStyle.textColor(.primary))
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(snapshot.artist.isEmpty ? "Spotify" : snapshot.artist)
                    .font(.subheadline)
                    .foregroundStyle(ExpandedNotchVisualStyle.textColor(.secondary))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .scaleEffect(isHighlighted ? 1 : 0.96)
        .opacity(isHighlighted ? 1 : 0.72)
        .onAppear(perform: highlight)
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
                    Color.white.opacity(0.045)
                    SpotifyGlyph()
                        .frame(width: 24, height: 24)
                        .opacity(0.7)
                }
            }
        }
        .compositingGroup()
        .clipShape(.rect(cornerRadius: 10))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.10), lineWidth: 0.75)
        }
        .shadow(color: .black.opacity(0.24), radius: 4, y: 2)
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        if snapshot.artist.isEmpty {
            return "Now playing \(snapshot.title)"
        }
        return "Now playing \(snapshot.title) by \(snapshot.artist)"
    }

    private func highlight() {
        guard !reduceMotion else {
            isHighlighted = true
            return
        }

        withAnimation(.spring(.bouncy(duration: 0.42))) {
            isHighlighted = true
        }
    }
}
