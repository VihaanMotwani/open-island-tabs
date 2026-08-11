import Testing
@testable import OpenIslandApp

struct SpotifyLaunchPolicyTests {
    @Test
    func selectingTheSpotifyTabDoesNotLaunchSpotify() {
        #expect(SpotifyLaunchPolicy.command(for: .tabSelection) == nil)
    }

    @Test
    func pressingTheUnavailableCardLaunchesSpotify() {
        #expect(SpotifyLaunchPolicy.command(for: .unavailableCard) == .open)
    }
}
