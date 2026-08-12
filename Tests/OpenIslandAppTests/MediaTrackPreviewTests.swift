import CoreGraphics
import Foundation
import Testing
@testable import OpenIslandApp

struct MediaTrackPreviewTests {
    @Test
    func previewUsesTheOriginalMacIslandDisplayDuration() {
        #expect(MediaTrackPreviewPolicy.displayDuration == 2.2)
    }

    @Test
    func previewUsesTheOriginalMacIslandLayoutMetrics() {
        #expect(MediaTrackPreviewPolicy.artworkSize == 50)
        #expect(MediaTrackPreviewPolicy.artworkCornerRadius == 12)
        #expect(MediaTrackPreviewPolicy.contentSpacing == 10)
        #expect(MediaTrackPreviewPolicy.textSpacing == 1)
        #expect(MediaTrackPreviewPolicy.maximumContentWidth == 250)
        #expect(MediaTrackPreviewPolicy.contentHeight == 50)
        #expect(MediaTrackPreviewPolicy.contentSafeAreaInset == 20)
        #expect(MediaTrackPreviewPolicy.bottomSafeAreaInset == 20)
    }

    @Test
    func previewUsesTheOriginalMacIslandNotchAwareSurface() {
        let size = MediaTrackPreviewPolicy.surfaceSize(
            availableScreenWidth: 1_440,
            notchWidth: 224,
            notchHeight: 38
        )

        #expect(size == CGSize(width: 290, height: 108))
        #expect(
            size.height
                < 38
                    + ExpandedNotchLayoutMetrics.tabSwitcherHeight
                    + ExpandedNotchLayoutMetrics.spotifyContentHeight
        )
    }

    @Test
    func externalDisplayPreviewUsesTheSameCompactContentChrome() {
        let size = MediaTrackPreviewPolicy.surfaceSize(
            availableScreenWidth: 1_440,
            notchWidth: 0,
            notchHeight: 32
        )

        #expect(size == CGSize(width: 290, height: 102))
    }

    @Test
    func previewWidthFollowsMetadataWhileRespectingTheNotchClearance() {
        let shortTrack = previewSnapshot(title: "A", artist: "B")
        let shortTrackSize = MediaTrackPreviewPolicy.surfaceSize(
            availableScreenWidth: 1_440,
            notchWidth: 224,
            notchHeight: 38,
            snapshot: shortTrack
        )
        let longTrack = previewSnapshot(
            title: String(repeating: "Long title ", count: 20),
            artist: "Artist"
        )
        let longTrackSize = MediaTrackPreviewPolicy.surfaceSize(
            availableScreenWidth: 1_440,
            notchWidth: 0,
            notchHeight: 32,
            snapshot: longTrack
        )

        #expect(shortTrackSize == CGSize(width: 244, height: 108))
        #expect(longTrackSize == CGSize(width: 290, height: 102))
    }

    @Test
    @MainActor
    func aNewTrackBrieflyOpensACompactPreviewWithoutChangingThePreferredTab() {
        let overlay = OverlayUICoordinator()
        let track = previewSnapshot(title: "Archangel", artist: "Burial")

        overlay.presentMediaTrackPreview(track)

        #expect(overlay.notchStatus == .opened)
        #expect(overlay.notchOpenReason == .mediaTrackChange)
        #expect(overlay.islandSurface == .mediaTrackPreview(track))
        #expect(overlay.selectedIslandTab == .agents)
        #expect(overlay.preferredIslandTab == .agents)
        #expect(overlay.hasPendingMediaTrackPreviewAutoCollapse)

        overlay.handleMediaTrackPreviewAutoCollapseDeadline()

        #expect(overlay.notchStatus == .closed)
        #expect(overlay.islandSurface == .sessionList())
        #expect(!overlay.hasPendingMediaTrackPreviewAutoCollapse)
    }

    @Test
    @MainActor
    func aLaterTrackRefreshesAnExistingPreview() {
        let overlay = OverlayUICoordinator()
        let firstTrack = previewSnapshot(title: "Archangel", artist: "Burial")
        let secondTrack = previewSnapshot(title: "Weird Fishes", artist: "Radiohead")

        overlay.presentMediaTrackPreview(firstTrack)
        overlay.presentMediaTrackPreview(secondTrack)

        #expect(overlay.islandSurface == .mediaTrackPreview(secondTrack))
        #expect(overlay.hasPendingMediaTrackPreviewAutoCollapse)
    }

    @Test
    @MainActor
    func trackChangesDoNotDisplaceUserOpenedOrAgentNotificationSurfaces() {
        let track = previewSnapshot(title: "Archangel", artist: "Burial")
        let userOpenedOverlay = OverlayUICoordinator()
        userOpenedOverlay.notchOpen(reason: .click)

        userOpenedOverlay.presentMediaTrackPreview(track)

        #expect(userOpenedOverlay.notchOpenReason == .click)
        #expect(userOpenedOverlay.islandSurface == .sessionList())
        #expect(!userOpenedOverlay.hasPendingMediaTrackPreviewAutoCollapse)

        let agentNotificationOverlay = OverlayUICoordinator()
        let notificationSurface = IslandSurface.sessionList(
            actionableSessionID: "approval-session"
        )
        agentNotificationOverlay.notchOpen(
            reason: .notification,
            surface: notificationSurface
        )

        agentNotificationOverlay.presentMediaTrackPreview(track)

        #expect(agentNotificationOverlay.notchOpenReason == .notification)
        #expect(agentNotificationOverlay.islandSurface == notificationSurface)
        #expect(!agentNotificationOverlay.hasPendingMediaTrackPreviewAutoCollapse)
    }
}

private func previewSnapshot(
    title: String,
    artist: String
) -> MediaPlaybackSnapshot {
    MediaPlaybackSnapshot(
        availability: .running,
        playbackState: .playing,
        title: title,
        artist: artist,
        album: "Album",
        artworkURL: URL(string: "https://example.com/artwork.jpg"),
        duration: 240,
        position: 0,
        volume: 0.5
    )
}
