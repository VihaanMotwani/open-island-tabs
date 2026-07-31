import Testing
@testable import OpenIslandApp

struct IslandDebugScenarioTests {
    @Test
    func allDebugScenarioSessionsAreDemoSessions() {
        for scenario in IslandDebugScenario.allCases {
            let snapshot = scenario.snapshot()
            #expect(snapshot.sessions.allSatisfy { $0.origin == .demo })
        }
    }

    @Test
    func spotifyPlayerScenarioCarriesDeterministicPlayingState() {
        let snapshot = IslandDebugScenario.spotifyPlayer.snapshot()

        #expect(snapshot.selectedTab == .spotify)
        #expect(snapshot.mediaSnapshot?.availability == .running)
        #expect(snapshot.mediaSnapshot?.playbackState == .playing)
        #expect(snapshot.mediaSnapshot?.title.isEmpty == false)
    }
}
