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
    func opensSpotifyOnlyWhenGivenTheExplicitOpenCommand() async {
        let executor = SpotifyScriptExecutorStub(responses: [[]])
        let provider = SpotifyPlaybackProvider(executor: executor)

        await provider.perform(.open)

        let scripts = await executor.executedScripts
        #expect(scripts == [#"tell application "Spotify" to activate"#])
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


struct SystemSpotifyScriptExecutorTests {
    @Test
    func repeatedAndChangedScriptsReturnFreshResults() async throws {
        let executor = SystemSpotifyScriptExecutor()
        #expect(try await executor.execute("return {\"first\"}") == ["first"])
        #expect(try await executor.execute("return {\"first\"}") == ["first"])
        #expect(try await executor.execute("return {\"second\"}") == ["second"])
        #expect(try await executor.execute("return {\"first\"}") == ["first"])
    }

    @Test
    func executionFailureDoesNotPoisonTheNextScript() async throws {
        let executor = SystemSpotifyScriptExecutor()
        do {
            _ = try await executor.execute("error \"test failure\"")
            Issue.record("Expected the AppleScript error to be propagated")
        } catch { }
        #expect(try await executor.execute("return {\"recovered\"}") == ["recovered"])
    }
}
