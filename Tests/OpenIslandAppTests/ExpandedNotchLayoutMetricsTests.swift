import Testing
@testable import OpenIslandApp

struct ExpandedNotchLayoutMetricsTests {
    @Test
    func spotifyLayoutKeepsComfortableMetadataWidthAtPreferredPanelSize() {
        let layout = ExpandedNotchLayoutMetrics.spotifyLayout(availableWidth: 496)

        #expect(layout.artworkSize == 104)
        #expect(layout.spacing == 16)
        #expect(layout.detailWidth == 376)
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
        #expect(ExpandedNotchLayoutMetrics.contentHorizontalInset == 24)
        #expect(ExpandedNotchLayoutMetrics.tabSwitcherHeight == 32)
        #expect(ExpandedNotchLayoutMetrics.tabControlHeight == 24)
        #expect(ExpandedNotchLayoutMetrics.sessionHeaderHeight == 34)
        #expect(ExpandedNotchLayoutMetrics.sessionFooterHeight == 22)
        #expect(ExpandedNotchLayoutMetrics.spotifyContentHeight == 132)
    }
}
