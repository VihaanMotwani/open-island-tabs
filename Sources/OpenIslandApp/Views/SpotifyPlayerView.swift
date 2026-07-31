import SwiftUI

struct SpotifyPlayerView: View {
    let model: SpotifyPlaybackModel

    @State private var scrubPosition: TimeInterval = 0
    @State private var volume: Double = 0
    @State private var isScrubbing = false
    @State private var isAdjustingVolume = false

    private var snapshot: MediaPlaybackSnapshot {
        model.snapshot
    }

    var body: some View {
        Group {
            if snapshot.availability == .running {
                player
            } else {
                unavailableState
                    .padding(.horizontal, ExpandedNotchLayoutMetrics.safeContentHorizontalInset)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 14)
        .onAppear(perform: syncControls)
        .onChange(of: snapshot.position) { _, _ in syncControls() }
        .onChange(of: snapshot.volume) { _, _ in syncControls() }
    }

    private var player: some View {
        GeometryReader { geometry in
            let contentWidth = ExpandedNotchLayoutMetrics.spotifyPlayerContentWidth(
                containerWidth: geometry.size.width
            )
            let layout = ExpandedNotchLayoutMetrics.spotifyLayout(
                availableWidth: contentWidth
            )

            HStack(spacing: layout.spacing) {
                artwork
                    .frame(width: layout.artworkSize, height: layout.artworkSize)

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(snapshot.title.isEmpty ? "Spotify" : snapshot.title)
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.92))
                            .lineLimit(1)

                        Text(snapshot.artist.isEmpty ? "Ready to play" : snapshot.artist)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .lineLimit(1)
                    }

                    VStack(spacing: 3) {
                        Slider(
                            value: $scrubPosition,
                            in: 0...max(snapshot.duration, 1),
                            onEditingChanged: { editing in
                                isScrubbing = editing
                                if !editing {
                                    model.perform(.seek(to: scrubPosition))
                                }
                            }
                        )
                        .tint(SpotifyPalette.green.opacity(0.82))
                        .controlSize(.mini)
                        .accessibilityLabel("Playback position")
                        .accessibilityValue(
                            "\(timeLabel(scrubPosition)) of \(timeLabel(snapshot.duration))"
                        )

                        HStack {
                            Text(timeLabel(scrubPosition))
                            Spacer()
                            Text(timeLabel(snapshot.duration))
                        }
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.white.opacity(0.32))
                        .accessibilityHidden(true)
                    }

                    ZStack {
                        HStack(spacing: 12) {
                            SpotifyTransportButton(
                                systemName: "backward.fill",
                                accessibilityLabel: "Previous track"
                            ) {
                                model.perform(.previous)
                            }

                            SpotifyPlayPauseButton(
                                isPlaying: snapshot.playbackState == .playing
                            ) {
                                model.perform(.togglePlayPause)
                            }

                            SpotifyTransportButton(
                                systemName: "forward.fill",
                                accessibilityLabel: "Next track"
                            ) {
                                model.perform(.next)
                            }
                        }

                        HStack(spacing: 10) {
                            Spacer()

                            Image(systemName: volume < 0.02 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.34))
                                .accessibilityHidden(true)

                            Slider(
                                value: $volume,
                                in: 0...1,
                                onEditingChanged: { editing in
                                    isAdjustingVolume = editing
                                    if !editing {
                                        model.perform(.setVolume(volume))
                                    }
                                }
                            )
                            .tint(.white.opacity(0.58))
                            .controlSize(.mini)
                            .frame(width: 88)
                            .accessibilityLabel("Spotify volume")
                        }
                    }
                }
                .frame(width: layout.detailWidth, alignment: .leading)
            }
            .frame(
                width: contentWidth,
                height: layout.artworkSize,
                alignment: .leading
            )
            .frame(
                width: geometry.size.width,
                height: layout.artworkSize,
                alignment: .center
            )
        }
        .frame(height: ExpandedNotchLayoutMetrics.preferredSpotifyArtworkSize)
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
                    Color.white.opacity(0.055)
                    SpotifyGlyph()
                        .frame(width: 42, height: 42)
                        .opacity(0.72)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(.white.opacity(0.07), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.22), radius: 5, y: 2)
        .accessibilityHidden(true)
    }

    private var unavailableState: some View {
        Button {
            model.perform(.open)
        } label: {
            VStack(spacing: 9) {
                SpotifyGlyph()
                    .frame(width: 32, height: 32)
                    .opacity(0.46)

                Text("Open Spotify")
                    .font(.headline)
                    .foregroundStyle(.white.opacity(0.64))

                Text("Playback controls will appear here")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.3))
            }
            .frame(
                maxWidth: .infinity,
                minHeight: ExpandedNotchLayoutMetrics.preferredSpotifyArtworkSize
            )
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.02))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(.white.opacity(0.055), lineWidth: 1)
                    }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Spotify")
    }

    private func syncControls() {
        if !isScrubbing {
            scrubPosition = snapshot.position
        }
        if !isAdjustingVolume {
            volume = snapshot.volume
        }
    }

    private func timeLabel(_ interval: TimeInterval) -> String {
        guard interval.isFinite, interval > 0 else { return "0:00" }
        let seconds = Int(interval.rounded(.down))
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}

private struct SpotifyTransportButton: View {
    let systemName: String
    let accessibilityLabel: String
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white.opacity(isHovered ? 0.82 : 0.58))
                .frame(width: 28, height: 28)
                .background(.white.opacity(isHovered ? 0.055 : 0), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

private struct SpotifyPlayPauseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    private var accessibilityLabel: String {
        isPlaying ? "Pause Spotify" : "Play Spotify"
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.black.opacity(0.84))
                .frame(width: 32, height: 32)
                .background(
                    SpotifyPalette.green.opacity(isHovered ? 1 : 0.9),
                    in: Circle()
                )
                .shadow(
                    color: SpotifyPalette.green.opacity(isHovered ? 0.16 : 0.08),
                    radius: isHovered ? 5 : 3
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
    }
}

struct SpotifyGlyph: View {
    var isDimmed = false

    var body: some View {
        Canvas { context, size in
            let bounds = CGRect(origin: .zero, size: size)
            context.fill(
                Path(ellipseIn: bounds),
                with: .color(SpotifyPalette.green.opacity(isDimmed ? 0.42 : 1))
            )

            let lineWidth = max(1.2, size.width * 0.075)
            for index in 0..<3 {
                let y = size.height * (0.38 + CGFloat(index) * 0.14)
                let leftX = size.width * (0.23 + CGFloat(index) * 0.025)
                let rightX = size.width * (0.79 - CGFloat(index) * 0.035)
                var wave = Path()
                wave.move(to: CGPoint(x: leftX, y: y))
                wave.addCurve(
                    to: CGPoint(x: rightX, y: y + size.height * 0.075),
                    control1: CGPoint(x: size.width * 0.4, y: y - size.height * 0.09),
                    control2: CGPoint(x: size.width * 0.63, y: y - size.height * 0.015)
                )
                context.stroke(
                    wave,
                    with: .color(.black.opacity(isDimmed ? 0.55 : 0.82)),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
        .accessibilityHidden(true)
    }
}

enum SpotifyPalette {
    static let green = Color(red: 0x1d / 255, green: 0xb9 / 255, blue: 0x54 / 255)
}
