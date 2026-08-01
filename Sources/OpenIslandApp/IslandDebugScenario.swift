import CoreGraphics
import Foundation
import OpenIslandCore

struct IslandDebugSnapshot {
    let title: String
    let summary: String
    let previewHeight: CGFloat
    let notchStatus: NotchStatus
    let notchOpenReason: NotchOpenReason?
    let islandSurface: IslandSurface
    let sessions: [AgentSession]
    let selectedSessionID: String?
    let selectedTab: IslandTab
    let mediaSnapshot: MediaPlaybackSnapshot?
    let tasks: [TaskItem]

    init(
        title: String,
        summary: String,
        previewHeight: CGFloat,
        notchStatus: NotchStatus,
        notchOpenReason: NotchOpenReason?,
        islandSurface: IslandSurface,
        sessions: [AgentSession],
        selectedSessionID: String?,
        selectedTab: IslandTab = .agents,
        mediaSnapshot: MediaPlaybackSnapshot? = nil,
        tasks: [TaskItem] = []
    ) {
        self.title = title
        self.summary = summary
        self.previewHeight = previewHeight
        self.notchStatus = notchStatus
        self.notchOpenReason = notchOpenReason
        self.islandSurface = islandSurface
        self.sessions = sessions
        self.selectedSessionID = selectedSessionID
        self.selectedTab = selectedTab
        self.mediaSnapshot = mediaSnapshot
        self.tasks = tasks
    }
}

enum IslandDebugScenario: String, CaseIterable, Identifiable {
    case closed
    case sessionList
    case claudeDemo
    case approvalCard
    case questionCard
    case completionCard
    case longCompletionCard
    case spotifyPlayer
    case tasksList

    var id: String { rawValue }

    var title: String {
        switch self {
        case .closed:
            "Closed Notch"
        case .sessionList:
            "Session List"
        case .claudeDemo:
            "Codex + Claude Launch Demo"
        case .approvalCard:
            "Approval Card"
        case .questionCard:
            "Question Card"
        case .completionCard:
            "Completion Card"
        case .longCompletionCard:
            "Long Completion Card"
        case .spotifyPlayer:
            "Spotify Player"
        case .tasksList:
            "To-do List"
        }
    }

    var summary: String {
        switch self {
        case .closed:
            "Collapsed idle/running notch with live count and attention affordance."
        case .sessionList:
            "Manual expanded list with running, active, and inactive session rows."
        case .claudeDemo:
            "Recording-ready Codex and Claude sessions with parallel active work, subagents, tasks, and a recent completion."
        case .approvalCard:
            "Auto-expanded permission surface with approve and deny actions."
        case .questionCard:
            "Auto-expanded question surface with selectable answer buttons."
        case .completionCard:
            "Auto-expanded finished-task reminder surface after a turn completes."
        case .longCompletionCard:
            "Long finished-task reply stays inside the card and scrolls internally."
        case .spotifyPlayer:
            "Expanded Spotify tab with deterministic playback metadata and controls."
        case .tasksList:
            "Expanded To-do tab with active, completed, editable, and scrollable tasks."
        }
    }

    func snapshot(at now: Date = .now) -> IslandDebugSnapshot {
        switch self {
        case .closed:
            let sessions = DebugSessionFactory.listSessions(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 78,
                notchStatus: .closed,
                notchOpenReason: nil,
                islandSurface: .sessionList(),
                sessions: sessions,
                selectedSessionID: sessions.first?.id,
                mediaSnapshot: Self.playingMediaSnapshot
            )

        case .sessionList:
            let sessions = DebugSessionFactory.listSessions(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 430,
                notchStatus: .opened,
                notchOpenReason: .click,
                islandSurface: .sessionList(),
                sessions: sessions,
                selectedSessionID: sessions.first?.id
            )

        case .claudeDemo:
            let sessions = DebugSessionFactory.launchDemoSessions(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 430,
                notchStatus: .opened,
                notchOpenReason: .click,
                islandSurface: .sessionList(),
                sessions: sessions,
                selectedSessionID: sessions.first?.id,
                mediaSnapshot: Self.playingMediaSnapshot
            )

        case .approvalCard:
            let session = DebugSessionFactory.approvalSession(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 330,
                notchStatus: .opened,
                notchOpenReason: .notification,
                islandSurface: .sessionList(actionableSessionID: session.id),
                sessions: DebugSessionFactory.notificationSessions(lead: session, now: now),
                selectedSessionID: session.id
            )

        case .questionCard:
            let session = DebugSessionFactory.questionSession(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 270,
                notchStatus: .opened,
                notchOpenReason: .notification,
                islandSurface: .sessionList(actionableSessionID: session.id),
                sessions: DebugSessionFactory.notificationSessions(lead: session, now: now),
                selectedSessionID: session.id
            )

        case .completionCard:
            let session = DebugSessionFactory.completionSession(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 250,
                notchStatus: .opened,
                notchOpenReason: .notification,
                islandSurface: .sessionList(actionableSessionID: session.id),
                sessions: DebugSessionFactory.notificationSessions(lead: session, now: now),
                selectedSessionID: session.id
            )

        case .longCompletionCard:
            let session = DebugSessionFactory.longCompletionSession(now: now)
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 290,
                notchStatus: .opened,
                notchOpenReason: .notification,
                islandSurface: .sessionList(actionableSessionID: session.id),
                sessions: DebugSessionFactory.notificationSessions(lead: session, now: now),
                selectedSessionID: session.id
            )

        case .spotifyPlayer:
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 236,
                notchStatus: .opened,
                notchOpenReason: .click,
                islandSurface: .sessionList(),
                sessions: [],
                selectedSessionID: nil,
                selectedTab: .spotify,
                mediaSnapshot: Self.playingMediaSnapshot
            )

        case .tasksList:
            return IslandDebugSnapshot(
                title: title,
                summary: summary,
                previewHeight: 340,
                notchStatus: .opened,
                notchOpenReason: .hover,
                islandSurface: .sessionList(),
                sessions: [],
                selectedSessionID: nil,
                selectedTab: .tasks,
                tasks: Self.demoTasks
            )
        }
    }

    private static let demoTasks: [TaskItem] = {
        let baseDate = Date(timeIntervalSince1970: 1_750_000_000)
        return [
            TaskItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!, title: "Review agent approvals", createdAt: baseDate),
            TaskItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!, title: "Reply to design feedback", createdAt: baseDate.addingTimeInterval(60)),
            TaskItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!, title: "Run the Swift test suite", createdAt: baseDate.addingTimeInterval(120)),
            TaskItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!, title: "Polish the Spotify player", createdAt: baseDate.addingTimeInterval(180)),
            TaskItem(id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!, title: "Capture final screenshots", createdAt: baseDate.addingTimeInterval(240)),
            TaskItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
                title: "Match the macIsland header",
                isCompleted: true,
                createdAt: baseDate.addingTimeInterval(300),
                completedAt: baseDate.addingTimeInterval(600),
                updatedAt: baseDate.addingTimeInterval(600)
            ),
            TaskItem(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
                title: "Keep the collapsed animations",
                isCompleted: true,
                createdAt: baseDate.addingTimeInterval(360),
                completedAt: baseDate.addingTimeInterval(660),
                updatedAt: baseDate.addingTimeInterval(660)
            ),
        ]
    }()

    private static let playingMediaSnapshot = MediaPlaybackSnapshot(
        availability: .running,
        playbackState: .playing,
        title: "Passionfruit",
        artist: "Drake",
        album: "More Life",
        artworkURL: URL(
            string: "https://image-cdn-ak.spotifycdn.com/image/ab67616d00001e024f0fd9dad63977146e685700"
        ),
        duration: 299,
        position: 102,
        volume: 0.62
    )
}

private enum DebugSessionFactory {
    static func listSessions(now: Date) -> [AgentSession] {
        [
            runningSession(now: now),
            recentCompletedSession(now: now),
            inactiveSession(
                id: "session-claude-research",
                workspace: "claude-research",
                initialPrompt: "我更关注获取的部分 我想在其他 app 里实时展示我的 usage。",
                latestPrompt: "为什么要查 Cursor 官方呢？这个事跟 Cursor 有什么关系？",
                assistant: "不建议按“最古老”来选。最古老不等于最轻量且最适合这个任务。",
                age: 27 * 60,
                now: now
            ),
            inactiveSession(
                id: "session-personal",
                workspace: "Personal",
                initialPrompt: "[Image #1]我给你截了 3 张图，这个是我现在 Cursor 里面可用的模型。",
                latestPrompt: "[Image #1]我给你截了 3 张图，这个是我现在 Cursor 里面可用的模型。",
                assistant: "这张图里的模型，严格说不是这个 `voice-input` App 应该选的模…",
                age: 32 * 60,
                now: now
            ),
            inactiveSession(
                id: "session-open-agent-sdk",
                workspace: "open-agent-sdk",
                initialPrompt: "OK，那现在你是不是需要提一个 PR？",
                latestPrompt: "那你直接提个 PR 吧",
                assistant: "PR 已经提好了：",
                age: 60 * 60,
                now: now
            ),
            inactiveSession(
                id: "session-voice-input",
                workspace: "voice-input",
                initialPrompt: "看看 voice-input 这个仓库，重点关注模型选型。",
                latestPrompt: "严格来说它应该选哪个模型？",
                assistant: "如果目标是轻量实时，不建议直接按 Cursor 现成套餐来映射。",
                age: 78 * 60,
                now: now
            ),
            inactiveSession(
                id: "session-agents",
                workspace: "agents",
                initialPrompt: "把你的分支和 worktree 都给我。",
                latestPrompt: "所以你是要先重启吗？",
                assistant: "已经重启了。现在跑的是新的 dev 进程。",
                age: 92 * 60,
                now: now
            ),
            inactiveSession(
                id: "session-claude",
                workspace: "claude-code",
                initialPrompt: "我们先把整个 notch 的背景换成纯黑。",
                latestPrompt: "下面那块空白要去掉。",
                assistant: "展开态高度已经改成按内容自适应。",
                age: 118 * 60,
                now: now
            ),
            inactiveSession(
                id: "session-hooks",
                workspace: "hooks",
                initialPrompt: "假如我想实时监控 Claude Code 的 usage 应该怎么做？",
                latestPrompt: "如果是在别的 app 里展示呢？",
                assistant: "代码里已经有几条更直接的路可以走。",
                age: 130 * 60,
                now: now
            ),
        ]
    }

    static func notificationSessions(lead: AgentSession, now: Date) -> [AgentSession] {
        var sessions = listSessions(now: now)
        if sessions.isEmpty {
            return [lead]
        }
        sessions[0] = lead
        return sessions
    }

    static func launchDemoSessions(now: Date) -> [AgentSession] {
        [
            codexLaunchSession(now: now),
            claudeRunningSession(now: now),
            claudeCompletedSession(now: now),
        ]
    }

    static func codexLaunchSession(now: Date) -> AgentSession {
        var session = AgentSession(
            id: "codex-demo-running",
            title: "Polish the Open Island launch",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .running,
            summary: "Verifying the mixed agent and music workflow.",
            updatedAt: now.addingTimeInterval(-18),
            jumpTarget: JumpTarget(
                terminalApp: "Codex.app",
                workspaceName: "open-island",
                paneTitle: "Polish the Open Island launch",
                workingDirectory: "/Users/demo/Projects/open-island",
                codexThreadID: "codex-demo-running"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "Polish the Open Island launch demo and keep the product in focus.",
                lastUserPrompt: "Run the final checks before we record.",
                lastAssistantMessage: "The launch flow is ready for a clean capture.",
                currentTool: "exec_command",
                currentCommandPreview: "swift test --filter IslandDebugScenarioTests",
                model: "gpt-5.6-sol",
                reasoningEffort: "xhigh",
                serviceTier: "priority",
                processedDuration: 12 * 60 + 24,
                currentTurnStartedAt: now.addingTimeInterval(-(6 * 60 + 42)),
                activeGoalStartedAt: now.addingTimeInterval(-(46 * 60)),
                activePlanStartedAt: now.addingTimeInterval(-(9 * 60)),
                isPlanMode: false
            )
        )
        session.isCodexAppSession = true
        return session
    }

    static func claudeRunningSession(now: Date) -> AgentSession {
        AgentSession(
            id: "claude-demo-running",
            title: "Claude · launch-film",
            tool: .claudeCode,
            origin: .demo,
            attachmentState: .attached,
            phase: .running,
            summary: "Refining the launch sequence and checking the final capture.",
            updatedAt: now.addingTimeInterval(-35),
            jumpTarget: JumpTarget(
                terminalApp: "Terminal",
                workspaceName: "launch-film",
                paneTitle: "claude ~/Projects/launch-film",
                workingDirectory: "/Users/demo/Projects/launch-film",
                terminalTTY: "/dev/ttys-demo-1"
            ),
            claudeMetadata: ClaudeSessionMetadata(
                initialUserPrompt: "Polish the Open Island launch sequence and prepare a clean 4K product cut.",
                lastUserPrompt: "Keep the motion subtle and let the product UI breathe.",
                lastAssistantMessage: "Reviewing the final timing pass and capture framing.",
                currentTool: "Bash",
                currentToolInputPreview: "swift test --filter LaunchSequenceTests",
                model: "claude-opus-4-1",
                worktreeBranch: "feat/launch-film",
                activeSubagents: [
                    ClaudeSubagentInfo(
                        agentID: "visual-review",
                        agentType: "Visual review",
                        taskDescription: "Check spacing and motion",
                        startedAt: now.addingTimeInterval(-75)
                    ),
                    ClaudeSubagentInfo(
                        agentID: "copy-review",
                        agentType: "Copy review",
                        summary: "Launch captions are concise and consistent.",
                        taskDescription: "Tighten launch captions",
                        startedAt: now.addingTimeInterval(-140)
                    ),
                ],
                activeTasks: [
                    ClaudeTaskInfo(
                        id: "storyboard",
                        title: "Lock the product storyboard",
                        status: .completed
                    ),
                    ClaudeTaskInfo(
                        id: "capture",
                        title: "Record the expanded Agents surface",
                        status: .inProgress
                    ),
                    ClaudeTaskInfo(
                        id: "export",
                        title: "Export the 4K launch cut",
                        status: .pending
                    ),
                ]
            )
        )
    }

    static func claudeCompletedSession(now: Date) -> AgentSession {
        AgentSession(
            id: "claude-demo-completed",
            title: "Claude · product-copy",
            tool: .claudeCode,
            origin: .demo,
            attachmentState: .attached,
            phase: .completed,
            summary: "Launch captions and product copy are ready.",
            updatedAt: now.addingTimeInterval(-2 * 60),
            jumpTarget: JumpTarget(
                terminalApp: "Terminal",
                workspaceName: "product-copy",
                paneTitle: "claude ~/Projects/product-copy",
                workingDirectory: "/Users/demo/Projects/product-copy",
                terminalTTY: "/dev/ttys-demo-3"
            ),
            claudeMetadata: ClaudeSessionMetadata(
                initialUserPrompt: "Write concise launch captions for the Open Island product video.",
                lastUserPrompt: "Keep every line direct and product-led.",
                lastAssistantMessage: "The final captions are tightened and ready for the edit.",
                model: "claude-sonnet-4",
                worktreeBranch: "feat/launch-copy"
            )
        )
    }

    static func runningSession(now: Date) -> AgentSession {
        var session = AgentSession(
            id: "session-running",
            title: "查找 VibeIsland 项目",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .running,
            summary: "Reading IslandPanelView.swift and AppModel.swift",
            updatedAt: now.addingTimeInterval(-45),
            jumpTarget: JumpTarget(
                terminalApp: "Codex.app",
                workspaceName: "open-island",
                paneTitle: "查找 VibeIsland 项目",
                workingDirectory: "/Users/wangruobing/Personal/open-island",
                codexThreadID: "session-running"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "把 DEV 完全重构成一个 debug 页面，我需要稳定验收这些 card 的 UI。",
                lastUserPrompt: "把我发送的内容完整显示一到两行，优先保留任务名称、模型和思考时间；如果可用空间仍然不够，再在内容末尾用省略号收尾。",
                lastAssistantMessage: "读取现有 notch 状态与事件路由，准备把提醒态从 session list 里拆出来。",
                currentTool: "exec_command",
                currentCommandPreview: "sed -n '1,260p' Sources/OpenIslandApp/Views/SettingsView.swift",
                model: "gpt-5.6-sol",
                reasoningEffort: "xhigh",
                serviceTier: "priority",
                processedDuration: 14 * 60 + 11,
                currentTurnStartedAt: now.addingTimeInterval(-(3_600 + 43 * 60 + 37)),
                activeGoalStartedAt: now.addingTimeInterval(-(26 * 3_600)),
                activePlanStartedAt: now.addingTimeInterval(-(22 * 60)),
                isPlanMode: true
            )
        )
        session.isCodexAppSession = true
        return session
    }

    static func recentCompletedSession(now: Date) -> AgentSession {
        AgentSession(
            id: "session-recent",
            title: "Codex · open-agent-sdk",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .completed,
            summary: "The session list now matches the original island more closely.",
            updatedAt: now.addingTimeInterval(-3 * 60),
            jumpTarget: JumpTarget(
                terminalApp: "Ghostty",
                workspaceName: "open-agent-sdk",
                paneTitle: "codex ~/Personal/open-agent-sdk",
                workingDirectory: "/Users/wangruobing/Personal/open-agent-sdk",
                terminalSessionID: "ghostty-recent"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "读一下这篇论文 https://arxiv.org/html/2603.28052",
                lastUserPrompt: "读一下这篇论文 https://arxiv.org/html/2603.28052v1 感觉和我们在做的 agent 很像。",
                lastAssistantMessage: "整理完了，已经提炼出和 autoreserach 相关的几段关键差异。"
            )
        )
    }

    static func inactiveSession(
        id: String,
        workspace: String,
        initialPrompt: String,
        latestPrompt: String,
        assistant: String,
        age: TimeInterval,
        now: Date
    ) -> AgentSession {
        AgentSession(
            id: id,
            title: "Codex · \(workspace)",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .completed,
            summary: assistant,
            updatedAt: now.addingTimeInterval(-age),
            jumpTarget: JumpTarget(
                terminalApp: "Ghostty",
                workspaceName: workspace,
                paneTitle: "codex ~/Personal/\(workspace)",
                workingDirectory: "/Users/wangruobing/Personal/\(workspace)",
                terminalSessionID: "ghostty-\(id)"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: initialPrompt,
                lastUserPrompt: latestPrompt,
                lastAssistantMessage: assistant
            )
        )
    }

    static func approvalSession(now: Date) -> AgentSession {
        AgentSession(
            id: "session-approval",
            title: "Codex · open-island",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .waitingForApproval,
            summary: "Allow Codex to run the focused Swift UI tests?",
            updatedAt: now.addingTimeInterval(-20),
            permissionRequest: PermissionRequest(
                title: "Approve release verification",
                summary: "Allow Codex to run the focused Swift UI tests?",
                affectedPath: "Tests/OpenIslandAppTests/IslandDebugScenarioTests.swift",
                primaryActionTitle: "Allow",
                secondaryActionTitle: "Deny"
            ),
            jumpTarget: JumpTarget(
                terminalApp: "Ghostty",
                workspaceName: "open-island",
                paneTitle: "codex ~/Projects/open-island",
                workingDirectory: "/Users/demo/Projects/open-island",
                terminalSessionID: "ghostty-approval"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "Polish the expanded notch controls for the launch.",
                lastUserPrompt: "Run the focused UI verification before exporting the build.",
                lastAssistantMessage: "The launch UI is ready for final verification.",
                currentTool: "exec_command",
                currentCommandPreview: "swift test --filter IslandDebugScenarioTests"
            )
        )
    }

    static func questionSession(now: Date) -> AgentSession {
        AgentSession(
            id: "session-question",
            title: "Codex · open-island",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .waitingForAnswer,
            summary: "这个提醒态需要自动收起吗？",
            updatedAt: now.addingTimeInterval(-18),
            questionPrompt: QuestionPrompt(
                title: "Which authentication method should we use?",
                questions: [
                    QuestionPromptItem(
                        question: "Which authentication method should we use?",
                        header: "Auth",
                        options: [
                            QuestionOption(label: "JWT tokens", description: "Stateless, scalable"),
                            QuestionOption(label: "Session cookies", description: "Traditional approach"),
                            QuestionOption(label: "OAuth 2.0", description: "Third-party auth"),
                            QuestionOption(label: "Other", description: "", allowsFreeform: true),
                        ]
                    )
                ]
            ),
            jumpTarget: JumpTarget(
                terminalApp: "Ghostty",
                workspaceName: "open-island",
                paneTitle: "codex ~/Personal/open-island",
                workingDirectory: "/Users/wangruobing/Personal/open-island",
                terminalSessionID: "ghostty-question"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "原产品看起来像是单 notch surface + 多 content surface。",
                lastUserPrompt: "我们应该怎么做？",
                lastAssistantMessage: "建议先把 approvalCard、questionCard、completionCard 拆成独立 surface。"
            )
        )
    }

    static func completionSession(now: Date) -> AgentSession {
        AgentSession(
            id: "session-completion",
            title: "Codex · open-island",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .completed,
            summary: "DEV 页面已经切到 mock-driven card 调试模式。",
            updatedAt: now.addingTimeInterval(-15),
            jumpTarget: JumpTarget(
                terminalApp: "Ghostty",
                workspaceName: "open-island",
                paneTitle: "codex ~/Personal/open-island",
                workingDirectory: "/Users/wangruobing/Personal/open-island",
                terminalSessionID: "ghostty-completion"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "这次我可能确实需要一些 mock 手段，让我能验收这些 Card 的 UI。",
                lastUserPrompt: "可以把 DEV 完全重构成一个 debug 页面。",
                lastAssistantMessage: "Plan 文件已写好。你的 hooks 触发情况如何？"
            )
        )
    }

    static func longCompletionSession(now: Date) -> AgentSession {
        AgentSession(
            id: "session-completion-long",
            title: "Codex · open-island",
            tool: .codex,
            origin: .demo,
            attachmentState: .attached,
            phase: .completed,
            summary: "README 提交已经完成，长回复现在应该在卡片内部滚动。",
            updatedAt: now.addingTimeInterval(-45),
            jumpTarget: JumpTarget(
                terminalApp: "Ghostty",
                workspaceName: "open-island",
                paneTitle: "codex ~/Personal/open-island",
                workingDirectory: "/Users/wangruobing/Personal/open-island",
                terminalSessionID: "ghostty-completion-long"
            ),
            codexMetadata: CodexSessionMetadata(
                initialUserPrompt: "帮我把这个 README 也提交了，然后把结果贴给我。",
                lastUserPrompt: "顺便确认一下当前工作树和验证情况。",
                lastAssistantMessage: """
[README.md](/Users/wangruobing/Personal/open-island/README.md) 的现有改动已经单独提交了，commit 是 `f196316`，message 是 `docs: update readme tagline`。

这轮没有跑测试，因为只是文案改动。当前工作树是干净的，`main` 相对 `origin/main` 现在是 `ahead 6`。

如果你要我继续做下一轮，我建议把工作切到独立 worktree 里，这样不会和共享 `main` 上的并行改动互相打架。

下一步我会先检查当前仓库状态，然后从 `origin/main` 新建一个 worktree 和分支，在新工作区里继续处理这个样式问题并做完验证。
"""
            )
        )
    }
}
