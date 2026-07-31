import Testing
@testable import OpenIslandApp

struct ExpandedNotchLayoutMetricsTests {
    @Test
    func spotifyLayoutKeepsComfortableMetadataWidthAtPreferredPanelSize() {
        let availableWidth = ExpandedNotchLayoutMetrics.spotifyPlayerContentWidth(
            containerWidth: 564
        )
        let layout = ExpandedNotchLayoutMetrics.spotifyLayout(availableWidth: availableWidth)

        #expect(layout.artworkSize == 96)
        #expect(layout.spacing == 16)
        #expect(layout.detailWidth == 368)
        #expect(availableWidth == 480)
    }

    @Test
    func spotifyLayoutShrinksArtworkBeforeCrowdingMetadata() {
        let layout = ExpandedNotchLayoutMetrics.spotifyLayout(availableWidth: 320)

        #expect(layout.artworkSize == 72)
        #expect(layout.spacing == 16)
        #expect(layout.detailWidth == 232)
    }

    @Test
    func expandedChromeUsesOneCompactSpacingSystem() {
        #expect(ExpandedNotchLayoutMetrics.contentHorizontalInset == 20)
        #expect(ExpandedNotchLayoutMetrics.silhouetteHorizontalInset == 22)
        #expect(ExpandedNotchLayoutMetrics.safeContentHorizontalInset == 42)
        #expect(ExpandedNotchLayoutMetrics.tabSwitcherHeight == 28)
        #expect(ExpandedNotchLayoutMetrics.tabControlHeight == 22)
        #expect(ExpandedNotchLayoutMetrics.sessionHeaderHeight == 32)
        #expect(ExpandedNotchLayoutMetrics.sessionFooterHeight == 22)
        #expect(ExpandedNotchLayoutMetrics.spotifyContentHeight == 124)
    }

    @Test
    func expandedSurfacesReserveTheConcaveSilhouetteOutsideVisibleContent() {
        let agentsWidth = ExpandedNotchLayoutMetrics.agentsSurfaceWidth(
            availableScreenWidth: 1_440
        )
        let spotifyWidth = ExpandedNotchLayoutMetrics.spotifySurfaceWidth(
            availableScreenWidth: 1_440
        )

        #expect(agentsWidth == 464)
        #expect(spotifyWidth == 564)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: agentsWidth) == 420)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: spotifyWidth) == 520)
        #expect(ExpandedNotchLayoutMetrics.spotifyPlayerContentWidth(containerWidth: spotifyWidth) == 480)
    }

    @Test
    func expandedSurfacesKeepSafeMarginsOnNarrowDisplays() {
        #expect(ExpandedNotchLayoutMetrics.agentsSurfaceWidth(availableScreenWidth: 390) == 358)
        #expect(ExpandedNotchLayoutMetrics.spotifySurfaceWidth(availableScreenWidth: 390) == 358)
        #expect(ExpandedNotchLayoutMetrics.visibleBodyWidth(surfaceWidth: 358) == 314)
    }

    @Test
    func agentsContentHeightReservesSetupHintOutsideTheSessionViewport() {
        #expect(
            ExpandedNotchLayoutMetrics.agentsContentHeight(
                rowHeights: [106, 40],
                showsInstallHooksHint: false
            ) == 230
        )
        #expect(
            ExpandedNotchLayoutMetrics.agentsContentHeight(
                rowHeights: [106, 40],
                showsInstallHooksHint: true
            ) == 278
        )
        #expect(
            ExpandedNotchLayoutMetrics.agentsContentHeight(
                rowHeights: [],
                showsInstallHooksHint: true
            ) == 156
        )
    }
}
