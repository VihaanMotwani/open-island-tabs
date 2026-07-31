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

    static let preferredAgentsVisibleBodyWidth: CGFloat = 420
    static let preferredSpotifyVisibleBodyWidth: CGFloat = 520
    static let screenEdgeMargin: CGFloat = 32
    static let silhouetteHorizontalInset = NotchShape.openedTopRadius
    static let contentHorizontalInset: CGFloat = 20
    static let safeContentHorizontalInset =
        silhouetteHorizontalInset + contentHorizontalInset
    static let tabSwitcherHeight: CGFloat = 28
    static let tabControlHeight: CGFloat = 22
    static let sessionHeaderHeight: CGFloat = 32
    static let sessionFooterHeight: CGFloat = 22
    static let spotifyContentHeight: CGFloat = 132
    static let agentsListChromeHeight: CGFloat = 84
    static let agentsEmptyStateHeight: CGFloat = 108
    static let installHooksHintReservedHeight: CGFloat = 58
    static let runningTimerDetailHeight: CGFloat = 42
    static let maximumSessionListHeight: CGFloat = 560
    static let preferredSpotifyArtworkSize: CGFloat = 104
    static let minimumSpotifyArtworkSize: CGFloat = 72
    static let minimumSpotifyDetailWidth: CGFloat = 240
    static let spotifySpacing: CGFloat = 16

    static func agentsSurfaceWidth(availableScreenWidth: CGFloat) -> CGFloat {
        min(
            preferredAgentsVisibleBodyWidth + (silhouetteHorizontalInset * 2),
            max(0, availableScreenWidth - screenEdgeMargin)
        )
    }

    static func spotifySurfaceWidth(availableScreenWidth: CGFloat) -> CGFloat {
        min(
            preferredSpotifyVisibleBodyWidth + (silhouetteHorizontalInset * 2),
            max(0, availableScreenWidth - screenEdgeMargin)
        )
    }

    static func visibleBodyWidth(surfaceWidth: CGFloat) -> CGFloat {
        max(0, surfaceWidth - (silhouetteHorizontalInset * 2))
    }

    static func spotifyPlayerContentWidth(containerWidth: CGFloat) -> CGFloat {
        max(0, containerWidth - (safeContentHorizontalInset * 2))
    }

    static func agentsContentHeight(
        rowHeights: [CGFloat],
        showsInstallHooksHint: Bool
    ) -> CGFloat {
        let sessionContentHeight: CGFloat
        if rowHeights.isEmpty {
            sessionContentHeight = agentsEmptyStateHeight
        } else {
            sessionContentHeight = min(
                rowHeights.reduce(CGFloat.zero, +),
                maximumSessionListHeight
            ) + agentsListChromeHeight
        }

        return sessionContentHeight
            + (showsInstallHooksHint ? installHooksHintReservedHeight : 0)
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
