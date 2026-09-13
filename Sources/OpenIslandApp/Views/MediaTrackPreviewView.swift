import SwiftUI

struct MediaTrackPreviewView: View {
    let snapshot: MediaPlaybackSnapshot
    var presentation: MusicPresentationModel?
    var artworkNamespace: Namespace.ID?
    var artworkIsSource = true

    var body: some View {
        HStack(spacing: MediaTrackPreviewPolicy.contentSpacing) {
            MusicArtworkView(track: presentation?.track,
                cornerRadius: MediaTrackPreviewPolicy.artworkCornerRadius,
                namespace: artworkNamespace, isSource: artworkIsSource)
                .frame(
                    width: MediaTrackPreviewPolicy.artworkSize,
                    height: MediaTrackPreviewPolicy.artworkSize
                )

            MusicTrackLabels(track: presentation?.track, fallback: snapshot, compact: true)
        }
        .frame(height: MediaTrackPreviewPolicy.contentHeight)
        .frame(
            maxWidth: MediaTrackPreviewPolicy.maximumContentWidth,
            alignment: .leading
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let title = presentation?.track?.title ?? snapshot.title
        let artist = presentation?.track?.artist ?? snapshot.artist
        if artist.isEmpty {
            return "Now playing \(title)"
        }
        return "Now playing \(title) by \(artist)"
    }
}
