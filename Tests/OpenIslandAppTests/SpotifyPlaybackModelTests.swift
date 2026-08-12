import Foundation
import Testing
@testable import OpenIslandApp

struct SpotifyPlaybackModelTests {
    @Test
    @MainActor
    func refreshPublishesOnlyDistinctTrackChangesAfterPriming() async {
        let initialTrack = mediaSnapshot(
            title: "Midnight City",
            artist: "M83",
            album: "Hurry Up, We're Dreaming",
            position: 12
        )
        let provider = MediaPlaybackProviderStub(snapshots: [
            initialTrack,
            mediaSnapshot(
                title: initialTrack.title,
                artist: initialTrack.artist,
                album: initialTrack.album,
                position: 13
            ),
            mediaSnapshot(
                title: initialTrack.title,
                artist: initialTrack.artist,
                album: initialTrack.album,
                playbackState: .paused,
                position: 13
            ),
            mediaSnapshot(
                title: "Archangel",
                artist: "Burial",
                album: "Untrue",
                position: 0
            ),
            mediaSnapshot(
                title: "Archangel",
                artist: "Burial",
                album: "Untrue",
                position: 1
            ),
        ])
        let model = SpotifyPlaybackModel(provider: provider)
        var trackChanges: [MediaPlaybackSnapshot] = []
        model.onTrackChange = { trackChanges.append($0) }

        await model.refresh()
        await model.refresh()
        await model.refresh()
        await model.refresh()
        await model.refresh()

        #expect(trackChanges.map(\.title) == ["Archangel"])
        #expect(trackChanges.map(\.artist) == ["Burial"])
    }

    @Test
    @MainActor
    func appModelRoutesDistinctTrackChangesIntoTheOverlay() async {
        let provider = MediaPlaybackProviderStub(snapshots: [
            mediaSnapshot(
                title: "Midnight City",
                artist: "M83",
                album: "Hurry Up, We're Dreaming",
                position: 12
            ),
            mediaSnapshot(
                title: "Archangel",
                artist: "Burial",
                album: "Untrue",
                position: 0
            ),
        ])
        let playback = SpotifyPlaybackModel(provider: provider)
        let taskStore = TaskStore(
            storageURL: FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathComponent("tasks.json")
        )
        let model = AppModel(
            taskStore: taskStore,
            spotifyPlayback: playback
        )

        await playback.refresh()
        await playback.refresh()

        #expect(
            model.islandSurface.mediaTrackPreviewSnapshot?.title
                == "Archangel"
        )
        #expect(model.notchOpenReason == .mediaTrackChange)
    }
}

private actor MediaPlaybackProviderStub: MediaPlaybackProviding {
    private var snapshots: [MediaPlaybackSnapshot]

    init(snapshots: [MediaPlaybackSnapshot]) {
        self.snapshots = snapshots
    }

    func fetchSnapshot() async -> MediaPlaybackSnapshot {
        snapshots.isEmpty ? .notRunning : snapshots.removeFirst()
    }

    func perform(_ command: MediaPlaybackCommand) async {}
}

private func mediaSnapshot(
    title: String,
    artist: String,
    album: String,
    playbackState: MediaPlaybackState = .playing,
    position: TimeInterval
) -> MediaPlaybackSnapshot {
    MediaPlaybackSnapshot(
        availability: .running,
        playbackState: playbackState,
        title: title,
        artist: artist,
        album: album,
        artworkURL: URL(string: "https://example.com/\(title).jpg"),
        duration: 240,
        position: position,
        volume: 0.5
    )
}
