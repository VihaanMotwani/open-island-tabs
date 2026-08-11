import Testing
@testable import OpenIslandApp

struct ClosedNotchActivityTests {
    @Test
    func pausedMusicUsesAQuietStaticEqualizer() {
        let pattern = MediaEqualizerPattern.make(for: .paused, reduceMotion: false)

        #expect(pattern.motion == .still)
        #expect(pattern.duration == 0)
        #expect(pattern.bars.map(\.restingScale) == [0.20, 0.76, 0.58, 0.82])
        #expect(pattern.bars.allSatisfy { $0.delay == nil })
    }

    @Test
    func playingMusicUsesFourDeterministicallyStaggeredBars() {
        let pattern = MediaEqualizerPattern.make(for: .playing, reduceMotion: false)

        #expect(pattern.motion == .equalizing)
        #expect(pattern.duration == 1.5)
        #expect(pattern.bars.count == 4)
        #expect(pattern.bars.map(\.restingScale) == [0.28, 0.38, 0.24, 0.32])
        #expect(pattern.bars.map(\.peakScale) == [0.68, 0.92, 0.74, 0.84])
        #expect(pattern.bars.map(\.delay) == [0.00, 0.19, 0.38, 0.57])
    }

    @Test
    func reducedMotionFreezesPlayingMusicAtAReadableFrame() {
        let pattern = MediaEqualizerPattern.make(
            for: .playing,
            animationEnabled: true,
            reduceMotion: true
        )

        #expect(pattern.motion == .still)
        #expect(pattern.duration == 0)
        #expect(pattern.bars.map(\.restingScale) == [0.36, 0.82, 0.56, 0.72])
        #expect(pattern.bars.allSatisfy { $0.delay == nil })
    }

    @Test
    func staticMusicPreferenceFreezesPlayingMusicWithoutHidingIt() {
        let style = IslandMusicActivityStyle.static
        let state = style.displayState(for: .playing)
        let pattern = MediaEqualizerPattern.make(
            for: state,
            animationEnabled: style.allowsAnimation,
            reduceMotion: false
        )

        #expect(state == .playing)
        #expect(pattern.motion == .still)
        #expect(pattern.duration == 0)
        #expect(pattern.bars.map(\.restingScale) == [0.36, 0.82, 0.56, 0.72])
    }

    @Test
    @MainActor
    func hiddenMusicPreferenceRemovesTheIndicatorAndCompactsBothLayouts() {
        let hiddenState = IslandMusicActivityStyle.hidden.displayState(for: .playing)
        #expect(hiddenState == .hidden)

        let externalVisible = V6ClosedPillGeometry.resolve(
            label: "Codex · editing",
            rightSlot: .count(3),
            mediaActivity: .playing,
            layout: .external,
            height: 32,
            physicalNotchWidth: 0,
            minWidth: 70
        )
        let externalHidden = V6ClosedPillGeometry.resolve(
            label: "Codex · editing",
            rightSlot: .count(3),
            mediaActivity: hiddenState,
            layout: .external,
            height: 32,
            physicalNotchWidth: 0,
            minWidth: 70
        )
        let macBookVisible = V6ClosedPillGeometry.resolve(
            label: nil,
            rightSlot: .count(3),
            mediaActivity: .playing,
            layout: .macbook,
            height: 32,
            physicalNotchWidth: 180,
            minWidth: 70
        )
        let macBookHidden = V6ClosedPillGeometry.resolve(
            label: nil,
            rightSlot: .count(3),
            mediaActivity: hiddenState,
            layout: .macbook,
            height: 32,
            physicalNotchWidth: 180,
            minWidth: 70
        )

        #expect(externalHidden.width < externalVisible.width)
        #expect(macBookHidden.width < macBookVisible.width)
        #expect(macBookHidden.leadingReserve < macBookVisible.leadingReserve)
    }

    @Test
    func macBookLeadingActivityMovesGridWithoutMovingWingOrEqualizer() {
        #expect(V6MacBookSlotMetrics.outerEdgeInset == 12)
        #expect(V6MacBookSlotMetrics.leadingActivitySpacing == 9)
        #expect(V6MacBookSlotMetrics.leadingNotchGap == 8)
        #expect(V6MacBookSlotMetrics.trailingNotchGap == 12)

        let contentWidth = V6MacBookSlotMetrics.leadingActivityContentWidth(
            mediaActivityWidth: 21
        )
        let reserve = V6MacBookSlotMetrics.leadingReserve(contentWidth: contentWidth)

        #expect(contentWidth == 54)
        #expect(reserve == 74)
        #expect(V6MacBookSlotMetrics.leadingSurfaceOrigin(
            notchLeft: 282,
            reserve: reserve
        ) == 208)
        #expect(V6MacBookSlotMetrics.leadingContentOrigin(
            notchLeft: 282,
            reserve: reserve
        ) == 220)
        #expect(V6MacBookSlotMetrics.leadingGridOrigin(
            notchLeft: 282,
            reserve: reserve,
            mediaActivityWidth: 21
        ) == 250)

        #expect(V6MacBookSlotMetrics.trailingReserve(contentWidth: 14.4) == 38.4)
        #expect(V6MacBookSlotMetrics.trailingContentOrigin(
            notchRight: 282,
            reserve: 38.4,
            contentWidth: 14.4
        ) == 294)
        #expect(V6MacBookSlotMetrics.trailingContentCenter(
            notchRight: 282,
            reserve: 38.4
        ) == 301.2)
        #expect(V6MacBookSlotMetrics.hardwareAlignmentOffset(
            leadingReserve: 74,
            trailingReserve: 38.4
        ) == -17.8)
    }
}
