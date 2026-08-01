import Testing
@testable import OpenIslandApp

struct ExpandedNotchLayoutMetricsTests {
    @Test
    func spotifyLayoutKeepsComfortableMetadataWidthAtPreferredPanelSize() {
        let availableWidth = ExpandedNotchLayoutMetrics.spotifyPlayerContentWidth(
            containerWidth: 390
        )
        let layout = ExpandedNotchLayoutMetrics.spotifyLayout(availableWidth: availableWidth)

        #expect(layout.artworkSize == 68)
        #expect(layout.spacing == 8.5)
        #expect(layout.detailWidth == 253.5)
        #expect(availableWidth == 330)
    }

    @Test
    func spotifyLayoutShrinksArtworkBeforeCrowdingMetadata() {
        let layout = ExpandedNotchLayoutMetrics.spotifyLayout(availableWidth: 292.5)

        #expect(layout.artworkSize == 64)
        #expect(layout.spacing == 8.5)
        #expect(layout.detailWidth == 220)
    }

    @Test
    func expandedChromeUsesOneCompactSpacingSystem() {
        #expect(ExpandedNotchLayoutMetrics.contentHorizontalInset == 15)
        #expect(ExpandedNotchLayoutMetrics.silhouetteHorizontalInset == 15)
        #expect(ExpandedNotchLayoutMetrics.safeContentHorizontalInset == 30)
        #expect(ExpandedNotchLayoutMetrics.tabSwitcherHeight == 36)
        #expect(ExpandedNotchLayoutMetrics.tabControlHeight == 26)
        #expect(ExpandedNotchLayoutMetrics.sessionHeaderHeight == 30)
        #expect(ExpandedNotchLayoutMetrics.sessionFooterHeight == 22)
        #expect(ExpandedNotchLayoutMetrics.spotifyContentHeight == 124)
        #expect(ExpandedNotchLayoutMetrics.maximumCompletionMessageHeight == 184)
    }

    @Test
    func expandedSurfacesReserveTheConcaveSilhouetteOutsideVisibleContent() {
        let agentsWidth = ExpandedNotchLayoutMetrics.agentsSurfaceWidth(
            availableScreenWidth: 1_440
        )
        let spotifyWidth = ExpandedNotchLayoutMetrics.spotifySurfaceWidth(
            availableScreenWidth: 1_440
        )
        let tasksWidth = ExpandedNotchLayoutMetrics.tasksSurfaceWidth(
            availableScreenWidth: 1_440
        )

        #expect(agentsWidth == 450)
        #expect(spotifyWidth == 390)
        #expect(tasksWidth == 410)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: agentsWidth) == 420)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: spotifyWidth) == 360)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: tasksWidth) == 380)
        #expect(ExpandedNotchLayoutMetrics.spotifyPlayerContentWidth(containerWidth: spotifyWidth) == 330)
    }

    @Test
    func expandedSurfacesKeepSafeMarginsOnNarrowDisplays() {
        #expect(ExpandedNotchLayoutMetrics.agentsSurfaceWidth(availableScreenWidth: 390) == 358)
        #expect(ExpandedNotchLayoutMetrics.spotifySurfaceWidth(availableScreenWidth: 390) == 358)
        #expect(ExpandedNotchLayoutMetrics.tasksSurfaceWidth(availableScreenWidth: 390) == 358)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: 358) == 328)
    }

    @Test
    func agentsContentHeightReservesSetupHintOutsideTheSessionViewport() {
        #expect(
            ExpandedNotchLayoutMetrics.agentsContentHeight(
                rowHeights: [106, 40],
                showsInstallHooksHint: false
            ) == 206
        )
        #expect(
            ExpandedNotchLayoutMetrics.agentsContentHeight(
                rowHeights: [106, 40],
                showsInstallHooksHint: true
            ) == 254
        )
        #expect(
            ExpandedNotchLayoutMetrics.agentsContentHeight(
                rowHeights: [],
                showsInstallHooksHint: true
            ) == 156
        )
    }

    @Test
    func tasksUseMacIslandDynamicHeightAndFiveRowCap() {
        #expect(ExpandedNotchLayoutMetrics.visibleTaskCount(totalCount: -1) == 0)
        #expect(ExpandedNotchLayoutMetrics.visibleTaskCount(totalCount: 8) == 5)
        #expect(ExpandedNotchLayoutMetrics.tasksExpandedHeight(totalCount: 0) == 124)
        #expect(ExpandedNotchLayoutMetrics.tasksExpandedHeight(totalCount: 1) == 154)
        #expect(ExpandedNotchLayoutMetrics.tasksExpandedHeight(totalCount: 3) == 238)
        #expect(ExpandedNotchLayoutMetrics.tasksExpandedHeight(totalCount: 5) == 260)
        #expect(ExpandedNotchLayoutMetrics.tasksContentHeight(totalCount: 5) == 270)
    }
}
