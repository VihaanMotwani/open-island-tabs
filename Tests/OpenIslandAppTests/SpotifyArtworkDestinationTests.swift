import Foundation
import Testing
@testable import OpenIslandApp

struct SpotifyArtworkDestinationTests {
    @Test
    func opensTheSpotifyApplicationWithoutNavigatingToTheCurrentTrack() {
        #expect(
            SpotifyArtworkDestination.url
                == URL(string: "spotify:")
        )
    }
}
