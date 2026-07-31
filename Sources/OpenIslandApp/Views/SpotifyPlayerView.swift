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
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 4)
        .padding(.bottom, 16)
        .onAppear(perform: syncControls)
        .onChange(of: snapshot.position) { _, _ in syncControls() }
        .onChange(of: snapshot.volume) { _, _ in syncControls() }
    }

    private var player: some View {
        GeometryReader { geometry in
            let artworkSize: CGFloat = 128
            let spacing: CGFloat = 20
            let detailWidth = max(0, geometry.size.width - artworkSize - spacing)

            HStack(spacing: spacing) {
                artwork
                    .frame(width: artworkSize, height: artworkSize)

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(snapshot.title.isEmpty ? "Spotify" : snapshot.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.94))
                            .lineLimit(1)

                        Text(snapshot.artist.isEmpty ? "Ready to play" : snapshot.artist)
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(.white.opacity(0.48))
                            .lineLimit(1)
                    }

                    VStack(spacing: 4) {
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
                        .tint(SpotifyPalette.green)
                        .controlSize(.mini)

                        HStack {
                            Text(timeLabel(scrubPosition))
                            Spacer()
                            Text(timeLabel(snapshot.duration))
                        }
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.28))
                    }

                    ZStack {
                        HStack(spacing: 18) {
                            playerButton(systemName: "backward.fill", size: 13) {
                                model.perform(.previous)
                            }

                            Button {
                                model.perform(.togglePlayPause)
                            } label: {
                                Image(systemName: snapshot.playbackState == .playing ? "pause.fill" : "play.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.88))
                                    .frame(width: 40, height: 40)
                                    .background(SpotifyPalette.green, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(snapshot.playbackState == .playing ? "Pause Spotify" : "Play Spotify")

                            playerButton(systemName: "forward.fill", size: 13) {
                                model.perform(.next)
                            }
                        }

                        HStack(spacing: 10) {
                            Spacer()

                            Image(systemName: volume < 0.02 ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.36))

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
                            .tint(.white.opacity(0.64))
                            .controlSize(.mini)
                            .frame(width: 96)
                            .accessibilityLabel("Spotify volume")
                        }
                    }
                }
                .frame(width: detailWidth, alignment: .leading)
            }
            .frame(width: geometry.size.width, alignment: .leading)
        }
        .frame(height: 128)
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.08), lineWidth: 1)
        }
    }

    private var unavailableState: some View {
        Button {
            model.perform(.open)
        } label: {
            VStack(spacing: 11) {
                SpotifyGlyph()
                    .frame(width: 38, height: 38)
                    .opacity(0.5)

                Text("Open Spotify")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))

                Text("Playback controls will appear here")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.26))
            }
            .frame(maxWidth: .infinity, minHeight: 128)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white.opacity(0.025))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(.white.opacity(0.06), lineWidth: 1)
                    }
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open Spotify")
    }

    private func playerButton(
        systemName: String,
        size: CGFloat,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundStyle(.white.opacity(0.7))
                .frame(width: 24, height: 28)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
