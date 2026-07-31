import Foundation

enum IslandTab: Equatable, Sendable {
    case agents
    case spotify
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
        return takeover == .completion && preferredTab == .spotify ? 7 : nil
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
