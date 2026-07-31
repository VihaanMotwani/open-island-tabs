import CoreGraphics

enum IslandChromeMetrics {
    static let openedShadowHorizontalInset: CGFloat = 18
    static let openedShadowBottomInset: CGFloat = 22
    static let closedShadowHorizontalInset: CGFloat = 12
    static let closedShadowBottomInset: CGFloat = 14
    static let closedHoverScale: CGFloat = 1.028
}

struct ExpandedNotchLayoutMetrics: Equatable, Sendable {
    struct SpotifyLayout: Equatable, Sendable {
        let artworkSize: CGFloat
        let spacing: CGFloat
        let detailWidth: CGFloat
    }

    static let preferredAgentsContentWidth: CGFloat = 420
    static let preferredSpotifyContentWidth: CGFloat = 520
    static let screenEdgeMargin: CGFloat = 32
    static let contentHorizontalInset: CGFloat = 20
    static let tabSwitcherHeight: CGFloat = 28
    static let tabControlHeight: CGFloat = 22
    static let sessionHeaderHeight: CGFloat = 32
    static let sessionFooterHeight: CGFloat = 22
    static let spotifyContentHeight: CGFloat = 132
    static let preferredSpotifyArtworkSize: CGFloat = 104
    static let minimumSpotifyArtworkSize: CGFloat = 72
    static let minimumSpotifyDetailWidth: CGFloat = 240
    static let spotifySpacing: CGFloat = 16

    static func agentsContentWidth(availableScreenWidth: CGFloat) -> CGFloat {
        min(
            preferredAgentsContentWidth,
            max(0, availableScreenWidth - screenEdgeMargin)
        )
    }

    static func spotifyContentWidth(availableScreenWidth: CGFloat) -> CGFloat {
        min(
            preferredSpotifyContentWidth,
            max(0, availableScreenWidth - screenEdgeMargin)
        )
    }

    static func spotifyPlayerContentWidth(containerWidth: CGFloat) -> CGFloat {
        max(0, containerWidth - (contentHorizontalInset * 2))
    }

    static func spotifyLayout(availableWidth: CGFloat) -> SpotifyLayout {
        let maximumArtworkSize = max(
            minimumSpotifyArtworkSize,
            availableWidth - minimumSpotifyDetailWidth - spotifySpacing
        )
        let artworkSize = min(preferredSpotifyArtworkSize, maximumArtworkSize)

        return SpotifyLayout(
            artworkSize: artworkSize,
            spacing: spotifySpacing,
            detailWidth: max(0, availableWidth - artworkSize - spotifySpacing)
        )
    }
}
