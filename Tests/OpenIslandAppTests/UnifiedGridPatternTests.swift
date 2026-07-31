import Testing
@testable import OpenIslandApp

struct UnifiedGridPatternTests {
    @Test
    func modesUseDistinctNineCellMotionPatterns() {
        let idle = UnifiedGridPattern.make(for: .idle, reduceMotion: false)
        let running = UnifiedGridPattern.make(for: .running, reduceMotion: false)
        let waiting = UnifiedGridPattern.make(for: .waiting, reduceMotion: false)

        #expect(idle.motion == .still)
        #expect(running.motion == .chevron)
        #expect(waiting.motion == .orbit)
        #expect(idle.cells.count == 9)
        #expect(running.cells.count == 9)
        #expect(waiting.cells.count == 9)
        #expect(idle.cells.allSatisfy { $0.delay == nil })
        #expect(running.cells.compactMap(\.delay).count == 9)
        #expect(waiting.cells.compactMap(\.delay).count == 8)
        #expect(waiting.cells[4].delay == nil)
    }

    @Test
    func runningAndWaitingFollowTheReferenceWavefronts() {
        let running = UnifiedGridPattern.make(for: .running, reduceMotion: false)
        let waiting = UnifiedGridPattern.make(for: .waiting, reduceMotion: false)

        #expect(running.duration == 0.65)
        #expect(running.cells.map(\.delay) == [
            0.09, 0.18, 0.27,
            0.00, 0.09, 0.18,
            0.09, 0.18, 0.27,
        ])
        #expect(waiting.duration == 0.95)
        #expect(waiting.cells.map(\.delay) == [
            0.00, 0.11, 0.22,
            0.77, nil, 0.33,
            0.66, 0.55, 0.44,
        ])
    }

    @Test
    func reducedMotionUsesDistinctStaticFrames() {
        let idle = UnifiedGridPattern.make(for: .idle, reduceMotion: true)
        let running = UnifiedGridPattern.make(for: .running, reduceMotion: true)
        let waiting = UnifiedGridPattern.make(for: .waiting, reduceMotion: true)

        #expect(idle.motion == .still)
        #expect(running.motion == .still)
        #expect(waiting.motion == .still)
        #expect(idle.cells.allSatisfy { $0.delay == nil })
        #expect(running.cells.allSatisfy { $0.delay == nil })
        #expect(waiting.cells.allSatisfy { $0.delay == nil })
        #expect(idle.cells.map(\.restingOpacity) != running.cells.map(\.restingOpacity))
        #expect(running.cells.map(\.restingOpacity) != waiting.cells.map(\.restingOpacity))
        #expect(waiting.cells[4].restingOpacity < waiting.cells[0].restingOpacity)
    }
}
