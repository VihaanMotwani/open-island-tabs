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
        let pattern = MediaEqualizerPattern.make(for: .playing, reduceMotion: true)

        #expect(pattern.motion == .still)
        #expect(pattern.duration == 0)
        #expect(pattern.bars.map(\.restingScale) == [0.36, 0.82, 0.56, 0.72])
        #expect(pattern.bars.allSatisfy { $0.delay == nil })
    }

    @Test
    func macBookSlotsBalanceOuterBreathingRoomAroundIndependentNotchGaps() {
        #expect(V6MacBookSlotMetrics.outerEdgeInset == 12)
        #expect(V6MacBookSlotMetrics.leadingNotchGap == 10)
        #expect(V6MacBookSlotMetrics.trailingNotchGap == 12)
        #expect(V6MacBookSlotMetrics.leadingReserve(contentWidth: 45) == 67)
        #expect(V6MacBookSlotMetrics.trailingReserve(contentWidth: 14.4) == 38.4)
        #expect(V6MacBookSlotMetrics.leadingContentOrigin == 12)
        #expect(V6MacBookSlotMetrics.trailingContentOrigin(
            notchRight: 282,
            reserve: 38.4,
            contentWidth: 14.4
        ) == 294)
        #expect(V6MacBookSlotMetrics.trailingContentCenter(
            notchRight: 282,
            reserve: 38.4
        ) == 301.2)
    }
}
