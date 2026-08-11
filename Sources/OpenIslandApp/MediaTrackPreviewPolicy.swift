import CoreGraphics
import Foundation

enum MediaTrackPreviewPolicy {
    static let displayDuration: TimeInterval = 2.2
    static let preferredVisibleBodyWidth: CGFloat = 300
    static let contentHeight: CGFloat = 64

    static func surfaceSize(
        availableScreenWidth: CGFloat,
        notchWidth: CGFloat,
        notchHeight: CGFloat
    ) -> CGSize {
        let preferredWidth = preferredVisibleBodyWidth
            + (ExpandedNotchLayoutMetrics.silhouetteHorizontalInset * 2)
        let notchSafeWidth = notchWidth
            + (ExpandedNotchLayoutMetrics.safeContentHorizontalInset * 2)
        let closedSurfaceSafeWidth: CGFloat
        if notchWidth > 0 {
            closedSurfaceSafeWidth = V6ClosedSurfaceMetrics.maximumNotchedWidth(
                notchWidth: notchWidth
            )
        } else {
            closedSurfaceSafeWidth = V6ClosedSurfaceMetrics.externalDisplayWidth
        }
        let maximumWidth = max(
            0,
            availableScreenWidth - ExpandedNotchLayoutMetrics.screenEdgeMargin
        )

        return CGSize(
            width: min(
                max(preferredWidth, notchSafeWidth, closedSurfaceSafeWidth),
                maximumWidth
            ),
            height: notchHeight + contentHeight
        )
    }
}
