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
        #expect(pattern.duration == 0.8)
        #expect(pattern.bars.count == 4)
        #expect(pattern.bars.allSatisfy { $0.restingScale == 0.20 })
        #expect(pattern.bars.allSatisfy { $0.peakScale == 1.00 })
        #expect(pattern.bars.map(\.delay) == [0.00, 0.13, 0.26, 0.39])
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
    func macBookSlotsUseIndependentPhysicalNotchGaps() {
        #expect(V6MacBookSlotMetrics.leadingNotchGap == 7)
        #expect(V6MacBookSlotMetrics.trailingNotchGap == 10)
        #expect(V6MacBookSlotMetrics.leadingContentOrigin(
            halfReserve: 58,
            contentWidth: 45
        ) == 6)
        #expect(V6MacBookSlotMetrics.trailingContentOrigin(notchRight: 282) == 292)
    }
}
