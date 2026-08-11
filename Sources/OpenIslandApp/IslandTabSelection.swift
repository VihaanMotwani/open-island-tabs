import Foundation

enum IslandTabTransitionDirection: Equatable, Sendable {
    case backward
    case stationary
    case forward
}

enum IslandTab: CaseIterable, Hashable, Identifiable, Sendable {
    case agents
    case spotify
    case tasks

    var id: IslandTab { self }

    var showsAgentUsage: Bool {
        self == .agents
    }

    func transitionDirection(from previousTab: IslandTab) -> IslandTabTransitionDirection {
        if order == previousTab.order {
            return .stationary
        }
        return order > previousTab.order ? .forward : .backward
    }

    private var order: Int {
        switch self {
        case .agents: 0
        case .spotify: 1
        case .tasks: 2
        }
    }
}

struct IslandTabVisibility: Equatable, Sendable {
    var showsSpotify = true
    var showsTasks = true

    var visibleTabs: [IslandTab] {
        var tabs: [IslandTab] = [.agents]
        if showsSpotify { tabs.append(.spotify) }
        if showsTasks { tabs.append(.tasks) }
        return tabs
    }
}

enum AgentTabTakeover: Equatable, Sendable {
    case actionRequired
    case completion
}

struct IslandTabSelectionState: Equatable, Sendable {
    private(set) var selectedTab: IslandTab = .agents
    private(set) var preferredTab: IslandTab = .agents
    private(set) var activeTakeover: AgentTabTakeover?

    mutating func select(
        _ tab: IslandTab,
        visibleTabs: Set<IslandTab> = Set(IslandTab.allCases)
    ) {
        let resolvedTab = visibleTabs.contains(tab) ? tab : .agents
        selectedTab = resolvedTab
        preferredTab = resolvedTab
    }

    mutating func reconcile(visibleTabs: Set<IslandTab>) {
        var allowedTabs = visibleTabs
        allowedTabs.insert(.agents)

        if !allowedTabs.contains(selectedTab) {
            selectedTab = .agents
        }
        if !allowedTabs.contains(preferredTab) {
            preferredTab = .agents
        }
    }

    @discardableResult
    mutating func beginAgentTakeover(_ takeover: AgentTabTakeover) -> TimeInterval? {
        activeTakeover = takeover
        selectedTab = .agents
        return takeover == .completion && preferredTab != .agents ? 7 : nil
    }

    mutating func resolveAgentTakeover() {
        activeTakeover = nil
        selectedTab = preferredTab
    }

    mutating func resolveCompletionTakeover() {
        guard activeTakeover == .completion else { return }
        resolveAgentTakeover()
    }
}
