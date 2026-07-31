import Foundation
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
        #expect(snapshot.mediaSnapshot?.title == "Passionfruit")
        #expect(snapshot.mediaSnapshot?.artist == "Drake")
        #expect(snapshot.mediaSnapshot?.album == "More Life")
        #expect(
            snapshot.mediaSnapshot?.artworkURL?.absoluteString
                == "https://image-cdn-ak.spotifycdn.com/image/ab67616d00001e024f0fd9dad63977146e685700"
        )
    }

    @Test
    func closedScenarioCarriesPlayingStateForTheAmbientIndicator() {
        let snapshot = IslandDebugScenario.closed.snapshot()

        #expect(snapshot.notchStatus == .closed)
        #expect(snapshot.mediaSnapshot?.availability == .running)
        #expect(snapshot.mediaSnapshot?.playbackState == .playing)
    }

    @Test
    func claudeDemoScenarioCoversCodexAndClaudeLaunchVideoStates() {
        let snapshot = IslandDebugScenario.claudeDemo.snapshot(
            at: Date(timeIntervalSince1970: 1_750_000_000)
        )

        #expect(snapshot.notchStatus == .opened)
        #expect(snapshot.selectedTab == .agents)
        #expect(snapshot.sessions.count == 3)
        #expect(snapshot.sessions.allSatisfy { $0.origin == .demo })
        #expect(snapshot.sessions.first?.tool == .codex)
        #expect(snapshot.sessions.contains { $0.tool == .codex })
        #expect(snapshot.sessions.contains { $0.tool == .claudeCode })
        #expect(snapshot.sessions.filter { $0.phase == .running }.count == 2)
        #expect(snapshot.sessions.contains { $0.phase == .completed })
        #expect(snapshot.mediaSnapshot?.availability == .running)
        #expect(snapshot.mediaSnapshot?.playbackState == .playing)

        let claudeSession = snapshot.sessions.first { $0.tool == .claudeCode }
        #expect(claudeSession?.claudeMetadata?.activeSubagents.count == 2)
        #expect(claudeSession?.claudeMetadata?.activeTasks.count == 3)
    }

    @Test @MainActor
    func debugScenarioSuppressesTheRealHookSetupHint() {
        let model = AppModel()

        model.loadDebugSnapshot(IslandDebugScenario.claudeDemo.snapshot())

        #expect(!model.shouldShowInstallHooksHint)
    }
}
