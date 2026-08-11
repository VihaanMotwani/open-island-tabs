import CoreGraphics
import Testing
@testable import OpenIslandApp

struct IslandTransitionMotionTests {
    @Test
    func openingMorphsTheSilhouetteAndStagesContentWithTheMacIslandRhythm() {
        let state = IslandTransitionMotionPolicy.visualState(
            for: .opened,
            openedSize: CGSize(width: 486, height: 350),
            closedSize: CGSize(width: 372, height: 38),
            closedHorizontalOffset: -4,
            openedTopCornerRadius: 15
        )

        #expect(IslandTransitionMotionPolicy.duration(for: .opened) == 0.40)
        #expect(state.size == CGSize(width: 486, height: 350))
        #expect(state.horizontalOffset == 0)
        #expect(state.topCornerRadius == 15)
        #expect(state.bottomCornerRadius == 20)
        #expect(state.openedContentOpacity == 1)
        #expect(state.openedContentScale == 1)
        #expect(state.openedContentBlurRadius == 0)
        #expect(state.openedContentVerticalOffset == 0)
        #expect(state.shadowRadius == 10)
    }

    @Test
    func reducedMotionDisablesTheSilhouetteSpring() {
        #expect(IslandTransitionMotionPolicy.shouldAnimate(reduceMotion: false))
        #expect(!IslandTransitionMotionPolicy.shouldAnimate(reduceMotion: true))
    }

    @Test
    @MainActor
    func closedMacBookGeometryKeepsTheMorphAlignedToTheHardwareNotch() {
        let geometry = V6ClosedPillGeometry.resolve(
            label: nil,
            rightSlot: .count(3),
            mediaActivity: .playing,
            layout: .macbook,
            height: 38,
            physicalNotchWidth: 224,
            minWidth: 70
        )

        #expect(abs(geometry.width - 336.4) < 0.001)
        #expect(abs(geometry.horizontalOffset - -17.8) < 0.001)
        #expect(geometry.height == 38)
    }

    @Test
    func closingReturnsToTheRealClosedSilhouetteWithAQuickerSettle() {
        let state = IslandTransitionMotionPolicy.visualState(
            for: .closed,
            openedSize: CGSize(width: 486, height: 350),
            closedSize: CGSize(width: 336.4, height: 38),
            closedHorizontalOffset: -17.8,
            openedTopCornerRadius: 15
        )

        #expect(IslandTransitionMotionPolicy.duration(for: .closed) == 0.30)
        #expect(state.size == CGSize(width: 336.4, height: 38))
        #expect(state.horizontalOffset == -17.8)
        #expect(state.topCornerRadius == 0)
        #expect(state.bottomCornerRadius == 19)
        #expect(state.openedContentOpacity == 0)
        #expect(state.openedContentScale == 0.8)
        #expect(state.openedContentBlurRadius == 10)
        #expect(state.openedContentVerticalOffset == 5)
        #expect(state.shadowRadius == 0)
    }
}
