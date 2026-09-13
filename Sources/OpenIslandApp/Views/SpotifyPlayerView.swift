// Player composition, artwork glow and paused scaling adapted from Boring Notch's
// NotchHomeView.swift (GPL-3.0), by Hugo Persson, Harsh Vardhan Goswami,
// Richard Kunkli, Mustafa Ramadan, and contributors. Modified for Open Island's
// Spotify controls, synchronized track presentation, and accessibility.
// See docs/music-ui.md and THIRD_PARTY_NOTICES.md.
import SwiftUI

enum SpotifyArtworkDestination {
    static let url = URL(string: "spotify:")!
}

struct SpotifyPlayerView: View {
    let model: SpotifyPlaybackModel
    var artworkNamespace: Namespace.ID?
    var artworkIsSource = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

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
        .padding(.bottom, 10)
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
                    Link(destination: SpotifyArtworkDestination.url) {
                        artwork
                            .frame(width: layout.artworkSize, height: layout.artworkSize)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Open Spotify")
                    .accessibilityHint("Opens in Spotify")
                    .help("Open in Spotify")

                    VStack(alignment: .leading, spacing: 7) {
                        MusicTrackLabels(track: model.presentation.track, fallback: snapshot)

                        VStack(spacing: 1) {
                            SpotifySeekSlider(
                                value: $scrubPosition,
                                upperBound: max(snapshot.duration, 1),
                                accessibilityValue: "\(timeLabel(scrubPosition)) of \(timeLabel(snapshot.duration))",
                                onEditingChanged: handleScrubbingChanged
                            )
                            HStack {
                                Text(timeLabel(scrubPosition))
                                Spacer()
                                Text(timeLabel(snapshot.duration))
                            }
                            .font(.system(size: 9, weight: .medium).monospacedDigit())
                            .foregroundStyle(.white.opacity(0.4))
                            .accessibilityHidden(true)
                        }

                        ZStack {
                            HStack(spacing: 17) {
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
                        .frame(height: 30)
                    }
                    .frame(width: layout.detailWidth)
            }
            .frame(
                width: contentWidth,
                height: ExpandedNotchLayoutMetrics.spotifyContentHeight - 16,
                alignment: .leading
            )
            .frame(
                width: geometry.size.width,
                height: ExpandedNotchLayoutMetrics.spotifyContentHeight - 16,
                alignment: .center
            )
        }
        .frame(height: ExpandedNotchLayoutMetrics.spotifyContentHeight - 16)
    }

    private var artwork: some View {
        ZStack {
            if let image = model.presentation.track?.artwork, !reduceTransparency {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(1.18)
                    .blur(radius: 18)
                    .opacity(snapshot.playbackState == .playing ? 0.3 : 0.08)
                    .id(model.presentation.track?.id)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
            MusicArtworkView(track: model.presentation.track, cornerRadius: 13,
                namespace: artworkNamespace, isSource: artworkIsSource)
                .scaleEffect(snapshot.playbackState == .playing || reduceMotion ? 1 : 0.9)
                .overlay(alignment: .bottomTrailing) {
                    SpotifyGlyph()
                        .frame(width: 16, height: 16)
                        .padding(3)
                        .background(.black, in: Circle())
                        .offset(x: 5, y: 5)
                        .accessibilityHidden(true)
                }
        }
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: model.presentation.track?.id)
        .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: snapshot.playbackState)
        .accessibilityHidden(true)
    }

    private var unavailableState: some View {
        Button {
            model.handleLaunchTrigger(.unavailableCard)
        } label: {
            HStack(spacing: 12) {
                SpotifyGlyph()
                    .frame(width: 30, height: 30)
                    .opacity(0.52)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Open Spotify")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ExpandedNotchVisualStyle.textColor(.primary))

                    Text("Playback controls will appear here")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundStyle(ExpandedNotchVisualStyle.textColor(.subdued))
                }

                Spacer(minLength: 0)

                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.38))
            }
            .padding(.horizontal, 14)
            .frame(
                maxWidth: .infinity,
                minHeight: 68
            )
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.white.opacity(0.035))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
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

private struct SpotifySeekSlider: View {
    @Binding var value: TimeInterval
    let upperBound: TimeInterval
    let accessibilityValue: String
    let onEditingChanged: (Bool) -> Void

    private var fraction: CGFloat {
        guard upperBound > 0 else { return 0 }
        return CGFloat(min(max(value / upperBound, 0), 1))
    }

    var body: some View {
        ZStack {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.white.opacity(0.12))
                        .frame(height: 3)

                    Capsule()
                        .fill(.white.opacity(0.88))
                        .frame(width: geometry.size.width * fraction, height: 3)

                    Circle()
                        .fill(.white.opacity(0.94))
                        .frame(width: 7, height: 7)
                        .offset(x: max(0, (geometry.size.width - 7) * fraction))
                }
                .frame(maxHeight: .infinity, alignment: .center)
            }

            Slider(
                value: $value,
                in: 0...upperBound,
                onEditingChanged: onEditingChanged
            )
            .opacity(0.001)
        }
        .frame(height: 12)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Playback position")
        .accessibilityValue(accessibilityValue)
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
                        : ExpandedNotchVisualStyle.textColor(.primary)
                )
                .frame(width: 28, height: 28)
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
                .font(.system(size: 22, weight: .semibold))
                .contentTransition(.symbolEffect(.replace))
                .transaction { if reduceMotion { $0.disablesAnimations = true } }
                .foregroundStyle(.white.opacity(isHovered ? 1 : 0.94))
                .frame(width: 30, height: 30)
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
                        : ExpandedNotchVisualStyle.textColor(.secondary)
                )
                .frame(width: 28, height: 28)
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
                .frame(width: 120)

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
