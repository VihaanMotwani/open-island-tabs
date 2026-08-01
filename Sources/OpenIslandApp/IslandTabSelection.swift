import Foundation

enum IslandTabTransitionDirection: Equatable, Sendable {
    case backward
    case stationary
    case forward
}

enum IslandTab: Hashable, Sendable {
    case agents
    case spotify
    case tasks

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

enum AgentTabTakeover: Equatable, Sendable {
    case actionRequired
    case completion
}

struct IslandTabSelectionState: Equatable, Sendable {
    private(set) var selectedTab: IslandTab = .agents
    private(set) var preferredTab: IslandTab = .agents
    private(set) var activeTakeover: AgentTabTakeover?

    mutating func select(_ tab: IslandTab) {
        selectedTab = tab
        preferredTab = tab
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
