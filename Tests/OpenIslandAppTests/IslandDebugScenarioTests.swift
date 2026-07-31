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
        #expect(snapshot.mediaSnapshot?.title.isEmpty == false)
    }

    @Test
    func closedScenarioCarriesPlayingStateForTheAmbientIndicator() {
        let snapshot = IslandDebugScenario.closed.snapshot()

        #expect(snapshot.notchStatus == .closed)
        #expect(snapshot.mediaSnapshot?.availability == .running)
        #expect(snapshot.mediaSnapshot?.playbackState == .playing)
    }

    @Test
    func claudeDemoScenarioCoversTheLaunchVideoSessionStates() {
        let snapshot = IslandDebugScenario.claudeDemo.snapshot(
            at: Date(timeIntervalSince1970: 1_750_000_000)
        )

        #expect(snapshot.notchStatus == .opened)
        #expect(snapshot.selectedTab == .agents)
        #expect(snapshot.sessions.count == 3)
        #expect(snapshot.sessions.allSatisfy {
            $0.origin == .demo && $0.tool == .claudeCode
        })
        #expect(snapshot.sessions.filter { $0.phase == .running }.count == 2)
        #expect(snapshot.sessions.contains { $0.phase == .completed })

        let runningSession = snapshot.sessions.first { $0.phase == .running }
        #expect(runningSession?.claudeMetadata?.activeSubagents.count == 2)
        #expect(runningSession?.claudeMetadata?.activeTasks.count == 3)
    }

    @Test @MainActor
    func debugScenarioSuppressesTheRealHookSetupHint() {
        let model = AppModel()

        model.loadDebugSnapshot(IslandDebugScenario.claudeDemo.snapshot())

        #expect(!model.shouldShowInstallHooksHint)
    }
}
