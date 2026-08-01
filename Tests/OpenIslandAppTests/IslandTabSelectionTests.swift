import Testing
@testable import OpenIslandApp

struct IslandTabSelectionTests {
    @Test
    func onlyAgentsTabShowsAgentUsage() {
        #expect(IslandTab.agents.showsAgentUsage)
        #expect(!IslandTab.spotify.showsAgentUsage)
        #expect(!IslandTab.tasks.showsAgentUsage)
    }

    @Test
    @MainActor
    func openingSpotifyTabSelectsItAndKeepsHoverCollapseBehavior() {
        let overlay = OverlayUICoordinator()

        overlay.openIslandTab(.spotify)

        #expect(overlay.selectedIslandTab == .spotify)
        #expect(overlay.preferredIslandTab == .spotify)
        #expect(overlay.notchStatus == .opened)
        #expect(overlay.notchOpenReason == .hover)
    }

    @Test
    func selectingSpotifyMakesItVisibleAndPreferred() {
        var state = IslandTabSelectionState()

        state.select(.spotify)

        #expect(state.selectedTab == .spotify)
        #expect(state.preferredTab == .spotify)
    }

    @Test
    func selectingTasksMakesItVisibleAndPreferred() {
        var state = IslandTabSelectionState()

        state.select(.tasks)

        #expect(state.selectedTab == .tasks)
        #expect(state.preferredTab == .tasks)
    }

    @Test
    func actionableAgentTakeoverRestoresTasksAfterResolution() {
        var state = IslandTabSelectionState()
        state.select(.tasks)

        state.beginAgentTakeover(.actionRequired)

        #expect(state.selectedTab == .agents)
        #expect(state.preferredTab == .tasks)

        state.resolveAgentTakeover()

        #expect(state.selectedTab == .tasks)
        #expect(state.activeTakeover == nil)
    }

    @Test
    func completionTakeoverRequestsSevenSecondTaskRestoration() {
        var state = IslandTabSelectionState()
        state.select(.tasks)

        let restorationDelay = state.beginAgentTakeover(.completion)

        #expect(state.selectedTab == .agents)
        #expect(state.preferredTab == .tasks)
        #expect(restorationDelay == 7)
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
