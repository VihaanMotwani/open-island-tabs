import Testing
@testable import OpenIslandApp

struct IslandTabSelectionTests {
    @Test
    func selectingSpotifyMakesItVisibleAndPreferred() {
        var state = IslandTabSelectionState()

        state.select(.spotify)

        #expect(state.selectedTab == .spotify)
        #expect(state.preferredTab == .spotify)
    }

    @Test
    func actionableAgentTakeoverRestoresSpotifyAfterResolution() {
        var state = IslandTabSelectionState()
        state.select(.spotify)

        state.beginAgentTakeover(.actionRequired)

        #expect(state.selectedTab == .agents)
        #expect(state.preferredTab == .spotify)
        #expect(state.activeTakeover == .actionRequired)

        state.resolveAgentTakeover()

        #expect(state.selectedTab == .spotify)
        #expect(state.activeTakeover == nil)
    }

    @Test
    func completionTakeoverRequestsSevenSecondSpotifyRestoration() {
        var state = IslandTabSelectionState()
        state.select(.spotify)

        let restorationDelay = state.beginAgentTakeover(.completion)

        #expect(state.selectedTab == .agents)
        #expect(state.preferredTab == .spotify)
        #expect(state.activeTakeover == .completion)
        #expect(restorationDelay == 7)
    }

    @Test
    func staleCompletionResolutionCannotOverrideNewActionRequiredTakeover() {
        var state = IslandTabSelectionState()
        state.select(.spotify)
        state.beginAgentTakeover(.completion)
        state.beginAgentTakeover(.actionRequired)

        state.resolveCompletionTakeover()

        #expect(state.selectedTab == .agents)
        #expect(state.preferredTab == .spotify)
        #expect(state.activeTakeover == .actionRequired)
    }
}
