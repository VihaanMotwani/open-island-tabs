import CoreGraphics
import Foundation
import OpenIslandCore
import SwiftUI

struct IslandTransitionVisualState: Equatable {
    let size: CGSize
    let horizontalOffset: CGFloat
    let topCornerRadius: CGFloat
    let bottomCornerRadius: CGFloat
    let openedContentOpacity: Double
    let openedContentScale: CGFloat
    let openedContentBlurRadius: CGFloat
    let openedContentVerticalOffset: CGFloat
    let shadowRadius: CGFloat
}

enum IslandTransitionMotionPolicy {
    static func shouldAnimate(reduceMotion: Bool) -> Bool {
        !reduceMotion
    }

    static func duration(for status: NotchStatus) -> TimeInterval {
        switch status {
        case .opened:
            0.40
        case .closed:
            0.30
        case .popping:
            0.30
        }
    }

    static func animation(for status: NotchStatus, reduceMotion: Bool) -> Animation? {
        guard shouldAnimate(reduceMotion: reduceMotion) else {
            return nil
        }

        switch status {
        case .opened, .closed:
            return Animation.spring(.bouncy(duration: duration(for: status)))
        case .popping:
            return Animation.spring(response: 0.3, dampingFraction: 0.5)
        }
    }

    static func visualState(
        for status: NotchStatus,
        openedSize: CGSize,
        closedSize: CGSize,
        closedHorizontalOffset: CGFloat,
        openedTopCornerRadius: CGFloat
    ) -> IslandTransitionVisualState {
        switch status {
        case .opened:
            IslandTransitionVisualState(
                size: openedSize,
                horizontalOffset: 0,
                topCornerRadius: openedTopCornerRadius,
                bottomCornerRadius: NotchShape.openedBottomRadius,
                openedContentOpacity: 1,
                openedContentScale: 1,
                openedContentBlurRadius: 0,
                openedContentVerticalOffset: 0,
                shadowRadius: 10
            )
        case .closed, .popping:
            IslandTransitionVisualState(
                size: closedSize,
                horizontalOffset: closedHorizontalOffset,
                topCornerRadius: 0,
                bottomCornerRadius: closedSize.height / 2,
                openedContentOpacity: 0,
                openedContentScale: 0.8,
                openedContentBlurRadius: 10,
                openedContentVerticalOffset: 5,
                shadowRadius: 0
            )
        }
    }
}
