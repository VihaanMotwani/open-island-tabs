// Shared album-art geometry adapted from TheBoredTeam/boring.notch ContentView.swift
// and components/Notch/NotchHomeView.swift (GPL-3.0), by Hugo Persson,
// Harsh Vardhan Goswami, Richard Kunkli, Mustafa Ramadan, and contributors.
// Open Island adaptation: synchronized cover/labels and Reduce Motion support.
// See docs/music-ui.md and THIRD_PARTY_NOTICES.md.
import SwiftUI

struct MusicArtworkView: View {
    let track: MusicPresentedTrack?
    var cornerRadius: CGFloat = 12
    var namespace: Namespace.ID?
    var isSource = true
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let image = track?.artwork {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .id(track?.id)
                        .transition(.opacity)
                } else {
                    Rectangle().fill(.white.opacity(0.07))
                    Image(systemName: "music.note")
                        .font(.system(size: geometry.size.width * 0.35, weight: .medium))
                        .foregroundStyle(.white.opacity(0.45))
                }
            }
        }
        .clipShape(.rect(cornerRadius: cornerRadius))
        .modifier(MusicArtworkGeometry(namespace: reduceMotion ? nil : namespace, isSource: isSource))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: track?.id)
        .accessibilityHidden(true)
    }
}

private struct MusicArtworkGeometry: ViewModifier {
    let namespace: Namespace.ID?
    let isSource: Bool
    func body(content: Content) -> some View {
        if let namespace {
            content.matchedGeometryEffect(id: "music-artwork", in: namespace, isSource: isSource)
        } else {
            content
        }
    }
}

struct MusicTrackLabels: View {
    let track: MusicPresentedTrack?
    let fallback: MediaPlaybackSnapshot
    var compact = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var key: MusicTrackKey { track?.id ?? MusicTrackKey(fallback) }

    var body: some View {
        ZStack(alignment: .leading) {
            VStack(alignment: .leading, spacing: 3) {
                Text(key.title.isEmpty ? "Spotify" : key.title)
                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.95))
                Text(key.artist.isEmpty ? "Ready to play" : key.artist)
                    .font(.system(size: compact ? 10 : 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
            }
            .lineLimit(1)
            .id(key)
            .transition(reduceMotion ? .identity : .asymmetric(
                insertion: .offset(y: 6).combined(with: .opacity),
                removal: .offset(y: -6).combined(with: .opacity)))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: compact ? 32 : 38)
        .clipped()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.25), value: key)
        .help([key.title, key.artist].filter { !$0.isEmpty }.joined(separator: " — "))
        .accessibilityElement(children: .combine)
    }
}
