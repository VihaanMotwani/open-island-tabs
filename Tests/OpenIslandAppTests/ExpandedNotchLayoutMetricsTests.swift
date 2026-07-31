import Testing
@testable import OpenIslandApp

struct ExpandedNotchLayoutMetricsTests {
    @Test
    func spotifyLayoutKeepsComfortableMetadataWidthAtPreferredPanelSize() {
        let availableWidth = ExpandedNotchLayoutMetrics.spotifyPlayerContentWidth(
            containerWidth: 520
        )
        let layout = ExpandedNotchLayoutMetrics.spotifyLayout(availableWidth: availableWidth)

        #expect(layout.artworkSize == 104)
        #expect(layout.spacing == 16)
        #expect(layout.detailWidth == 360)
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
        #expect(ExpandedNotchLayoutMetrics.tabSwitcherHeight == 28)
        #expect(ExpandedNotchLayoutMetrics.tabControlHeight == 22)
        #expect(ExpandedNotchLayoutMetrics.sessionHeaderHeight == 32)
        #expect(ExpandedNotchLayoutMetrics.sessionFooterHeight == 22)
        #expect(ExpandedNotchLayoutMetrics.spotifyContentHeight == 132)
    }

    @Test
    func expandedSurfacesStayCompactOnAFullWidthMacBookDisplay() {
        #expect(ExpandedNotchLayoutMetrics.agentsContentWidth(availableScreenWidth: 1_440) == 420)
        #expect(ExpandedNotchLayoutMetrics.spotifyContentWidth(availableScreenWidth: 1_440) == 520)
    }

    @Test
    func expandedSurfacesKeepSafeMarginsOnNarrowDisplays() {
        #expect(ExpandedNotchLayoutMetrics.agentsContentWidth(availableScreenWidth: 390) == 358)
        #expect(ExpandedNotchLayoutMetrics.spotifyContentWidth(availableScreenWidth: 390) == 358)
    }
}
