import SwiftUI

struct MediaActivityIndicator: View {
    let state: MediaActivityState
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPlaying: Bool {
        state == .playing
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(
                        SpotifyPalette.green.opacity(isPlaying ? 0.15 : 0.06)
                    )
                    .symbolEffect(
                        .pulse,
                        options: .repeating,
                        isActive: isPlaying && !reduceMotion
                    )
                    .accessibilityHidden(true)

                Image(systemName: "music.note")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundStyle(
                        SpotifyPalette.green.opacity(isPlaying ? 0.96 : 0.46)
                    )
                    .accessibilityHidden(true)
            }
            .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
        .help(isPlaying ? "Spotify is playing" : "Spotify is paused")
        .accessibilityLabel("Spotify")
        .accessibilityValue(isPlaying ? "Playing" : "Paused")
        .accessibilityHint("Opens Spotify controls")
    }
}
