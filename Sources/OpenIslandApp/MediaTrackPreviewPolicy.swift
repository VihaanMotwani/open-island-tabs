import AppKit
import CoreGraphics
import Foundation

enum MediaTrackPreviewPolicy {
    static let displayDuration: TimeInterval = 2.2
    static let artworkSize: CGFloat = 50
    static let artworkCornerRadius: CGFloat = 12
    static let contentSpacing: CGFloat = 10
    static let textSpacing: CGFloat = 1
    static let maximumContentWidth: CGFloat = 250
    static let contentHeight: CGFloat = 50
    static let contentSafeAreaInset: CGFloat = 20
    static let bottomSafeAreaInset: CGFloat = 20
    static let notchWidthInset: CGFloat = 20

    static func surfaceSize(
        availableScreenWidth: CGFloat,
        notchWidth: CGFloat,
        notchHeight: CGFloat,
        snapshot: MediaPlaybackSnapshot? = nil
    ) -> CGSize {
        let contentWidth = snapshot.map(measuredContentWidth(for:))
            ?? maximumContentWidth
        let preferredWidth = contentWidth + (contentSafeAreaInset * 2)
        let notchSafeWidth = notchWidth + notchWidthInset
        let maximumWidth = max(
            0,
            availableScreenWidth - ExpandedNotchLayoutMetrics.screenEdgeMargin
        )

        return CGSize(
            width: min(
                max(preferredWidth, notchSafeWidth),
                maximumWidth
            ),
            height: notchHeight + contentHeight + bottomSafeAreaInset
        )
    }

    private static func measuredContentWidth(
        for snapshot: MediaPlaybackSnapshot
    ) -> CGFloat {
        let titleFont = NSFont.systemFont(
            ofSize: NSFont.systemFontSize,
            weight: .semibold
        )
        let artistFont = NSFont.systemFont(
            ofSize: NSFont.smallSystemFontSize
        )
        let titleWidth = (snapshot.title as NSString).size(
            withAttributes: [.font: titleFont]
        ).width
        let artistWidth = (snapshot.artist as NSString).size(
            withAttributes: [.font: artistFont]
        ).width
        let metadataWidth = ceil(max(titleWidth, artistWidth))

        return min(
            maximumContentWidth,
            artworkSize + contentSpacing + metadataWidth
        )
    }
}
