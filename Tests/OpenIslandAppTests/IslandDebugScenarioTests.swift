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
        #expect(
            snapshot.mediaSnapshot?.contentURL?.absoluteString
                == "spotify:track:3GfOAdcoc3X5GPiiXmpBjK"
        )
    }

    @Test @MainActor
    func tasksScenarioCarriesAndLoadsDeterministicTaskState() {
        let snapshot = IslandDebugScenario.tasksList.snapshot()
        let storageURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathComponent("tasks.json")
        let model = AppModel(taskStore: TaskStore(storageURL: storageURL))

        model.loadDebugSnapshot(snapshot)

        #expect(snapshot.selectedTab == .tasks)
        #expect(snapshot.tasks.count == 7)
        #expect(snapshot.tasks.filter(\.isCompleted).count == 2)
        #expect(model.taskStore.tasks == snapshot.tasks)
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

    @Test
    func approvalScenarioUsesLaunchSafeSyntheticCopy() {
        let snapshot = IslandDebugScenario.approvalCard.snapshot()
        let session = snapshot.sessions.first

        #expect(session?.phase == .waitingForApproval)
        #expect(session?.permissionRequest?.title == "Approve release verification")
        #expect(
            session?.permissionRequest?.summary
                == "Allow Codex to run the focused Swift UI tests?"
        )
        #expect(session?.jumpTarget?.workingDirectory == "/Users/demo/Projects/open-island")
        #expect(
            session?.codexMetadata?.currentCommandPreview
                == "swift test --filter IslandDebugScenarioTests"
        )
        #expect(
            session?.codexMetadata?.lastUserPrompt
                == "Run the focused UI verification before exporting the build."
        )
    }

    @Test @MainActor
    func debugScenarioSuppressesTheRealHookSetupHint() {
        let model = AppModel()

        model.loadDebugSnapshot(IslandDebugScenario.claudeDemo.snapshot())

        #expect(!model.shouldShowInstallHooksHint)
    }
}
