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
    static let preferredSpotifyVisibleBodyWidth: CGFloat = 360
    static let preferredTasksVisibleBodyWidth: CGFloat = 380
    static let screenEdgeMargin: CGFloat = 32
    static let silhouetteHorizontalInset = NotchShape.openedTopRadius
    static let contentHorizontalInset: CGFloat = 15
    static let safeContentHorizontalInset =
        silhouetteHorizontalInset + contentHorizontalInset
    static let headerControlButtonSize: CGFloat = 22
    static let headerControlSpacing: CGFloat = 8
    static let headerControlCount: CGFloat = 3
    static let headerControlButtonsWidth =
        (headerControlButtonSize * headerControlCount)
        + (headerControlSpacing * (headerControlCount - 1))
    static let notchHeaderHorizontalPadding = safeContentHorizontalInset
    static let tabSwitcherHeight: CGFloat = 36
    static let tabControlHeight: CGFloat = 26
    static let tabSegmentedControlWidth: CGFloat = 216
    static let sessionHeaderHeight: CGFloat = 30
    static let sessionFooterHeight: CGFloat = 22
    static let spotifyContentHeight: CGFloat = 124
    static let agentsListChromeHeight: CGFloat = 60
    static let agentsEmptyStateHeight: CGFloat = 108
    static let installHooksHintReservedHeight: CGFloat = 48
    static let runningTimerDetailHeight: CGFloat = 34
    static let maximumCompletionMessageHeight: CGFloat = 184
    static let maximumSessionListHeight: CGFloat = 200
    static let agentCardCornerRadius: CGFloat = 12
    static let agentCardHorizontalPadding: CGFloat = 12
    static let agentCardSpacing: CGFloat = 8
    static let agentCardFillOpacity = 0.08
    static let agentCompletedCardFillOpacity = 0.05
    static let agentListVerticalPadding: CGFloat = 8
    static let preferredSpotifyArtworkSize: CGFloat = 68
    static let minimumSpotifyArtworkSize: CGFloat = 64
    static let minimumSpotifyDetailWidth: CGFloat = 220
    static let spotifySpacing: CGFloat = 8.5
    static let tasksMinimumExpandedHeight: CGFloat = 124
    static let tasksMaximumExpandedHeight: CGFloat = 260
    static let tasksSegmentedControlHeight: CGFloat = 32
    static let tasksInputRowHeight: CGFloat = 36
    static let taskRowHeight: CGFloat = 34
    static let tasksVerticalPadding: CGFloat = 18
    static let taskRowSpacing: CGFloat = 8
    static let maximumVisibleTaskRows = 5

    static func agentsSurfaceWidth(availableScreenWidth: CGFloat) -> CGFloat {
        min(
            preferredAgentsVisibleBodyWidth + (silhouetteHorizontalInset * 2),
            max(0, availableScreenWidth - screenEdgeMargin)
        )
    }

    static func spotifySurfaceWidth(
        availableScreenWidth: CGFloat,
        notchWidth: CGFloat = 0
    ) -> CGFloat {
        compactSurfaceWidth(
            preferredVisibleBodyWidth: preferredSpotifyVisibleBodyWidth,
            availableScreenWidth: availableScreenWidth,
            notchWidth: notchWidth
        )
    }

    static func tasksSurfaceWidth(
        availableScreenWidth: CGFloat,
        notchWidth: CGFloat = 0
    ) -> CGFloat {
        compactSurfaceWidth(
            preferredVisibleBodyWidth: preferredTasksVisibleBodyWidth,
            availableScreenWidth: availableScreenWidth,
            notchWidth: notchWidth
        )
    }

    static func minimumNotchHeaderSurfaceWidth(notchWidth: CGFloat) -> CGFloat {
        max(
            0,
            notchWidth + (2 * (notchHeaderHorizontalPadding + headerControlButtonsWidth))
        )
    }

    private static func compactSurfaceWidth(
        preferredVisibleBodyWidth: CGFloat,
        availableScreenWidth: CGFloat,
        notchWidth: CGFloat
    ) -> CGFloat {
        let preferredSurfaceWidth =
            preferredVisibleBodyWidth + (silhouetteHorizontalInset * 2)
        let headerSafeWidth = notchWidth > 0
            ? minimumNotchHeaderSurfaceWidth(notchWidth: notchWidth)
            : 0

        return min(
            max(preferredSurfaceWidth, headerSafeWidth),
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
            let rowSpacing = CGFloat(max(rowHeights.count - 1, 0)) * agentCardSpacing
            let cardStackHeight = rowHeights.reduce(CGFloat.zero, +)
                + rowSpacing
                + (agentListVerticalPadding * 2)
            sessionContentHeight = min(cardStackHeight, maximumSessionListHeight)
                + agentsListChromeHeight
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

    static func visibleTaskCount(totalCount: Int) -> Int {
        min(max(totalCount, 0), maximumVisibleTaskRows)
    }

    static func tasksExpandedHeight(totalCount: Int) -> CGFloat {
        let visibleRows = visibleTaskCount(totalCount: totalCount)
        let rowsHeight = CGFloat(visibleRows) * taskRowHeight
        let spacingHeight = CGFloat(max(visibleRows - 1, 0)) * taskRowSpacing
        let measured = tasksVerticalPadding * 2
            + tasksSegmentedControlHeight
            + tasksInputRowHeight
            + 16
            + rowsHeight
            + spacingHeight

        return min(
            max(measured, tasksMinimumExpandedHeight),
            tasksMaximumExpandedHeight
        )
    }

    static func tasksContentHeight(totalCount: Int) -> CGFloat {
        tasksExpandedHeight(totalCount: totalCount)
            + (visibleTaskCount(totalCount: totalCount) == maximumVisibleTaskRows ? 10 : 0)
    }
}
