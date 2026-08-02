import Foundation
import Testing
@testable import OpenIslandApp

struct SpotifyArtworkDestinationTests {
    @Test
    func usesTheCurrentTracksSpotifyURL() {
        let trackURL = URL(string: "spotify:track:3GfOAdcoc3X5GPiiXmpBjK")!
        var snapshot = MediaPlaybackSnapshot.notRunning
        snapshot.contentURL = trackURL

        #expect(SpotifyArtworkDestination.url(for: snapshot) == trackURL)
    }

    @Test
    func fallsBackToOpeningTheSpotifyAppWithoutTrackMetadata() {
        #expect(
            SpotifyArtworkDestination.url(for: .notRunning)
                == URL(string: "spotify:")
        )
    }
}
