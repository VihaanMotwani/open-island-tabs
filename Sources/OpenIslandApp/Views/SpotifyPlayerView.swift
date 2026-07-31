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
        .padding(.top, 8)
        .padding(.bottom, 12)
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

            VStack(spacing: 0) {
                HStack(spacing: layout.spacing) {
                    artwork
                        .frame(width: layout.artworkSize, height: layout.artworkSize)

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(snapshot.title.isEmpty ? "Spotify" : snapshot.title)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(ExpandedNotchVisualStyle.textColor(.primary))
                                .lineLimit(1)
                                .truncationMode(.tail)

                            Text(snapshot.artist.isEmpty ? "Ready to play" : snapshot.artist)
                                .font(.body)
                                .foregroundStyle(ExpandedNotchVisualStyle.textColor(.secondary))
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        Image(systemName: "waveform")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundStyle(SpotifyPalette.green.opacity(0.72))
                            .accessibilityHidden(true)
                    }
                    .frame(width: layout.detailWidth, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 10)

                HStack(spacing: 9) {
                    Text(timeLabel(scrubPosition))
                        .frame(width: 32, alignment: .leading)

                    Slider(
                        value: $scrubPosition,
                        in: 0...max(snapshot.duration, 1),
                        onEditingChanged: handleScrubbingChanged
                    )
                    .tint(ExpandedNotchVisualStyle.textColor(.primary))
                    .controlSize(.mini)
                    .accessibilityLabel("Playback position")
                    .accessibilityValue(
                        "\(timeLabel(scrubPosition)) of \(timeLabel(snapshot.duration))"
                    )

                    Text(remainingTimeLabel)
                        .frame(width: 38, alignment: .trailing)
                }
                .font(ExpandedNotchTypographyRole.playbackTime.font)
                .foregroundStyle(ExpandedNotchVisualStyle.textColor(.tertiary))

                Spacer(minLength: 8)

                ZStack {
                    HStack(spacing: 34) {
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

                    HStack {
                        Spacer()
                        SpotifyVolumeButton(
                            volume: $volume,
                            onEditingChanged: handleVolumeChanged
                        )
                    }
                }
                .frame(height: 40)
            }
            .frame(
                width: contentWidth,
                height: ExpandedNotchLayoutMetrics.spotifyContentHeight - 20,
                alignment: .leading
            )
            .frame(
                width: geometry.size.width,
                height: ExpandedNotchLayoutMetrics.spotifyContentHeight - 20,
                alignment: .center
            )
        }
        .frame(height: ExpandedNotchLayoutMetrics.spotifyContentHeight - 20)
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
                    Color.white.opacity(0.035)
                    SpotifyGlyph()
                        .frame(width: 36, height: 36)
                        .opacity(0.56)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    .white.opacity(ExpandedNotchVisualStyle.dividerOpacity),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.18), radius: 4, y: 2)
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
                    .foregroundStyle(ExpandedNotchVisualStyle.textColor(.secondary))

                Text("Playback controls will appear here")
                    .font(.caption)
                    .foregroundStyle(ExpandedNotchVisualStyle.textColor(.subdued))
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

    private var remainingTimeLabel: String {
        "-\(timeLabel(max(0, snapshot.duration - scrubPosition)))"
    }

    private func handleScrubbingChanged(_ editing: Bool) {
        isScrubbing = editing
        if !editing {
            model.perform(.seek(to: scrubPosition))
        }
    }

    private func handleVolumeChanged(_ editing: Bool) {
        isAdjustingVolume = editing
        if !editing {
            model.perform(.setVolume(volume))
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    isHovered
                        ? .white
                        : ExpandedNotchVisualStyle.textColor(.secondary)
                )
                .frame(width: 38, height: 38)
                .background(.white.opacity(isHovered ? 0.08 : 0), in: Circle())
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
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.white.opacity(isHovered ? 1 : 0.94))
                .frame(width: 40, height: 40)
                .background(.white.opacity(isHovered ? 0.10 : 0), in: Circle())
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

private struct SpotifyVolumeButton: View {
    @Binding var volume: Double
    let onEditingChanged: (Bool) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false
    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Image(systemName: volume < 0.02 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(
                    isHovered || isPresented
                        ? ExpandedNotchVisualStyle.textColor(.primary)
                        : ExpandedNotchVisualStyle.textColor(.tertiary)
                )
                .frame(width: 38, height: 38)
                .background(.white.opacity(isHovered || isPresented ? 0.08 : 0), in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(reduceMotion ? nil : .easeOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            HStack(spacing: 10) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)

                Slider(
                    value: $volume,
                    in: 0...1,
                    onEditingChanged: onEditingChanged
                )
                .controlSize(.small)
                .frame(width: 140)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(12)
        }
        .accessibilityLabel("Spotify volume")
        .accessibilityValue("\(Int((volume * 100).rounded())) percent")
        .help("Spotify volume")
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
