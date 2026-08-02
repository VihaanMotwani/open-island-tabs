import Foundation
import Testing
@testable import OpenIslandApp

struct SpotifyPlaybackProviderTests {
    @Test
    func mapsSpotifyTrackFieldsIntoGenericMediaSnapshot() async {
        let executor = SpotifyScriptExecutorStub(
            responses: [[
                "running",
                "playing",
                "Midnight City",
                "M83",
                "Hurry Up, We're Dreaming",
                "https://example.com/artwork.jpg",
                "spotify:track:3GfOAdcoc3X5GPiiXmpBjK",
                "244000",
                "61.5",
                "37",
            ]]
        )
        let provider = SpotifyPlaybackProvider(executor: executor)

        let snapshot = await provider.fetchSnapshot()

        #expect(snapshot.availability == .running)
        #expect(snapshot.playbackState == .playing)
        #expect(snapshot.title == "Midnight City")
        #expect(snapshot.artist == "M83")
        #expect(snapshot.album == "Hurry Up, We're Dreaming")
        #expect(snapshot.artworkURL == URL(string: "https://example.com/artwork.jpg"))
        #expect(snapshot.contentURL == URL(string: "spotify:track:3GfOAdcoc3X5GPiiXmpBjK"))
        #expect(snapshot.duration == 244)
        #expect(snapshot.position == 61.5)
        #expect(snapshot.volume == 0.37)
    }

    @Test
    func reportsSpotifyAsUnavailableWithoutInventingTrackMetadata() async {
        let executor = SpotifyScriptExecutorStub(responses: [["notRunning"]])
        let provider = SpotifyPlaybackProvider(executor: executor)

        let snapshot = await provider.fetchSnapshot()

        #expect(snapshot == .notRunning)
    }

    @Test
    func clampsSeekAndVolumeBeforeSendingCommandsToSpotify() async {
        let executor = SpotifyScriptExecutorStub(responses: [[], []])
        let provider = SpotifyPlaybackProvider(executor: executor)

        await provider.perform(.seek(to: -8))
        await provider.perform(.setVolume(1.4))

        let scripts = await executor.executedScripts
        #expect(scripts.count == 2)
        #expect(scripts[0].contains("set player position to 0.0"))
        #expect(scripts[1].contains("set sound volume to 100"))
    }
}

private actor SpotifyScriptExecutorStub: SpotifyScriptExecuting {
    private var responses: [[String]]
    private(set) var executedScripts: [String] = []

    init(responses: [[String]]) {
        self.responses = responses
    }

    func execute(_ source: String) async throws -> [String] {
        executedScripts.append(source)
        return responses.isEmpty ? [] : responses.removeFirst()
    }
}
