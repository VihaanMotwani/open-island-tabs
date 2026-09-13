import AppKit
import Testing
@testable import OpenIslandApp

@MainActor
struct SpotifySeekControlTests {
    @Test
    func draggingBackAndForthTracksThePointerAndCommitsOnRelease() {
        let slider = SpotifySeekControl(frame: NSRect(x: 0, y: 0, width: 208, height: 22))
        slider.minValue = 0
        slider.maxValue = 200
        var values: [Double] = []
        var editing: [Bool] = []
        slider.onValueChange = { values.append($0) }
        slider.onEditingChanged = { editing.append($0) }

        slider.mouseDown(with: mouse(.leftMouseDown, x: 104))
        slider.mouseDragged(with: mouse(.leftMouseDragged, x: 184))
        slider.mouseDragged(with: mouse(.leftMouseDragged, x: 24))
        #expect(editing == [true])
        slider.mouseUp(with: mouse(.leftMouseUp, x: 64))

        #expect(values == [100, 180, 20, 60])
        #expect(editing == [true, false])
        #expect(slider.doubleValue == 60)
    }

    @Test(arguments: [(54.0, 50.0), (-20.0, 0.0), (250.0, 200.0)])
    func clickingSeeksToThePointerAndClampsAtTheEnds(point: Double, expected: Double) {
        let slider = SpotifySeekControl(frame: NSRect(x: 0, y: 0, width: 208, height: 22))
        slider.maxValue = 200
        slider.doubleValue = 150
        var commits = 0
        slider.onEditingChanged = { if !$0 { commits += 1 } }
        slider.mouseDown(with: mouse(.leftMouseDown, x: point))
        slider.mouseUp(with: mouse(.leftMouseUp, x: point))
        #expect(slider.doubleValue == expected)
        #expect(commits == 1)
    }

    @Test
    func disabledSliderDoesNotStartSeeking() {
        let slider = SpotifySeekControl(frame: NSRect(x: 0, y: 0, width: 208, height: 22))
        slider.isEnabled = false
        var edits: [Bool] = []
        slider.onEditingChanged = { edits.append($0) }
        slider.mouseDown(with: mouse(.leftMouseDown, x: 104))
        slider.mouseUp(with: mouse(.leftMouseUp, x: 104))
        #expect(edits.isEmpty)
    }

    private func mouse(_ type: NSEvent.EventType, x: CGFloat) -> NSEvent {
        NSEvent.mouseEvent(with: type, location: NSPoint(x: x, y: 11),
            modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil,
            eventNumber: 0, clickCount: 1, pressure: 1)!
    }
}
