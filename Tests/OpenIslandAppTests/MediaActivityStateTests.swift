import Testing
@testable import OpenIslandApp

struct MediaActivityStateTests {
    @Test
    func spotifyActivityReflectsPlaybackWithoutShowingWhenSpotifyIsClosed() {
        #expect(MediaActivityState(snapshot: .notRunning) == .hidden)

        var snapshot = MediaPlaybackSnapshot.notRunning
        snapshot.availability = .running
        snapshot.playbackState = .paused
        #expect(MediaActivityState(snapshot: snapshot) == .paused)

        snapshot.playbackState = .playing
        #expect(MediaActivityState(snapshot: snapshot) == .playing)
    }
}
