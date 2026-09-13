import Foundation
import Testing
@testable import OpenIslandApp

struct SpotifyPlaybackModelTests {
    @Test
    @MainActor
    func rapidSeeksStayInOrderAndKeepTheLatestPositionVisible() async {
        let provider = SeekingPlaybackProvider(snapshot: mediaSnapshot(
            title: "Track", artist: "Artist", album: "Album", position: 30))
        let model = SpotifyPlaybackModel(provider: provider)
        await model.refresh()
        model.perform(.seek(to: 180))
        while provider.pendingCommand == nil { await Task.yield() }
        model.perform(.seek(to: 40))
        await model.refresh()
        #expect(model.snapshot.position == 40)
        #expect(provider.commands == [.seek(to: 180)])

        provider.pendingCommand?.resume()
        provider.pendingCommand = nil
        while provider.pendingCommand == nil { await Task.yield() }
        #expect(provider.commands == [.seek(to: 180), .seek(to: 40)])
        #expect(model.snapshot.position == 40)
        provider.pendingCommand?.resume()
        provider.pendingCommand = nil
        while provider.snapshot.position != 40 { await Task.yield() }
        await model.refresh()
        #expect(model.snapshot.position == 40)
    }

    @Test
    @MainActor
    func pollingWhileASeekIsPendingPreservesTheRequestedPosition() async {
        let provider = SeekingPlaybackProvider(snapshot: mediaSnapshot(
            title: "Track", artist: "Artist", album: "Album", position: 30))
        let model = SpotifyPlaybackModel(provider: provider)
        await model.refresh()
        model.perform(.seek(to: 180))
        while provider.pendingCommand == nil { await Task.yield() }
        await model.refresh()
        #expect(model.snapshot.position == 180)
        provider.pendingCommand?.resume()
        provider.pendingCommand = nil
    }

    @Test
    @MainActor
    func aPollStartedBeforeSeekingCannotMoveTheSliderBack() async {
        let initial = mediaSnapshot(title: "Track", artist: "Artist", album: "Album", position: 30)
        let provider = SeekingPlaybackProvider(snapshot: initial)
        let model = SpotifyPlaybackModel(provider: provider)
        await model.refresh()
        provider.holdNextRead = true
        let oldPoll = Task { await model.refresh() }
        while provider.pendingRead == nil { await Task.yield() }

        model.perform(.seek(to: 180))
        #expect(model.snapshot.position == 180)
        provider.pendingRead?.resume(returning: initial)
        provider.pendingRead = nil
        await oldPoll.value
        #expect(model.snapshot.position == 180)

        while provider.pendingCommand == nil { await Task.yield() }
        provider.pendingCommand?.resume()
        provider.pendingCommand = nil
    }

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

@MainActor
private final class SeekingPlaybackProvider: MediaPlaybackProviding {
    var snapshot: MediaPlaybackSnapshot
    var commands: [MediaPlaybackCommand] = []
    var holdNextRead = false
    var pendingRead: CheckedContinuation<MediaPlaybackSnapshot, Never>?
    var pendingCommand: CheckedContinuation<Void, Never>?
    init(snapshot: MediaPlaybackSnapshot) { self.snapshot = snapshot }
    func fetchSnapshot() async -> MediaPlaybackSnapshot {
        if holdNextRead {
            holdNextRead = false
            return await withCheckedContinuation { pendingRead = $0 }
        }
        return snapshot
    }
    func perform(_ command: MediaPlaybackCommand) async {
        commands.append(command)
        await withCheckedContinuation { pendingCommand = $0 }
        if case let .seek(position) = command { snapshot.position = position }
    }
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
        artworkURL: nil, // Playback-event tests do not fetch artwork from the network.
        duration: 240,
        position: position,
        volume: 0.5
    )
}
