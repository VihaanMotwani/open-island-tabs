import AppKit
import SwiftUI

/// One native control owns drawing, pointer tracking, keyboard input and AX values.
struct SpotifySeekSlider: NSViewRepresentable {
    @Binding var value: TimeInterval
    let upperBound: TimeInterval
    let accessibilityValue: String
    let onEditingChanged: (Bool) -> Void

    func makeNSView(context: Context) -> SpotifySeekControl {
        SpotifySeekControl(frame: .zero)
    }

    func updateNSView(_ slider: SpotifySeekControl, context: Context) {
        slider.minValue = 0
        slider.maxValue = upperBound.isFinite && upperBound > 0 ? upperBound : 1
        slider.isEnabled = upperBound.isFinite && upperBound > 0
        slider.onValueChange = { value = $0 }
        slider.onEditingChanged = onEditingChanged
        if !slider.isTrackingPointer {
            slider.doubleValue = value.isFinite ? min(max(value, 0), slider.maxValue) : 0
        }
        slider.toolTip = accessibilityValue
        slider.needsDisplay = true
    }
}

final class SpotifySeekControl: NSSlider {
    var onValueChange: (Double) -> Void = { _ in }
    var onEditingChanged: (Bool) -> Void = { _ in }
    private(set) var isTrackingPointer = false
    private let horizontalInset: CGFloat = 4

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        isContinuous = true
        target = self
        action = #selector(accessibleValueChanged)
        focusRingType = .exterior
        setAccessibilityLabel("Playback position")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var intrinsicContentSize: NSSize {
        NSSize(width: NSView.noIntrinsicMetric, height: 22)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDown(with event: NSEvent) {
        guard isEnabled, bounds.width > horizontalInset * 2 else { return }
        window?.makeFirstResponder(self)
        isTrackingPointer = true
        onEditingChanged(true)
        moveKnob(with: event)
    }

    override func mouseDragged(with event: NSEvent) {
        guard isTrackingPointer else { return }
        moveKnob(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        guard isTrackingPointer else { return }
        moveKnob(with: event)
        isTrackingPointer = false
        onEditingChanged(false)
        needsDisplay = true
    }

    private func moveKnob(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let width = bounds.width - horizontalInset * 2
        let fraction = min(max((point.x - bounds.minX - horizontalInset) / width, 0), 1)
        doubleValue = minValue + Double(fraction) * (maxValue - minValue)
        onValueChange(doubleValue)
        needsDisplay = true
    }

    @objc private func accessibleValueChanged() {
        onEditingChanged(true)
        onValueChange(doubleValue)
        onEditingChanged(false)
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        let width = max(0, bounds.width - horizontalInset * 2)
        let track = NSRect(x: bounds.minX + horizontalInset, y: bounds.midY - 1.5, width: width, height: 3)
        NSColor.white.withAlphaComponent(isEnabled ? 0.12 : 0.06).setFill()
        NSBezierPath(roundedRect: track, xRadius: 1.5, yRadius: 1.5).fill()
        let fraction = maxValue > minValue ? min(max((doubleValue - minValue) / (maxValue - minValue), 0), 1) : 0
        let centerX = track.minX + width * fraction
        NSColor.white.withAlphaComponent(isEnabled ? 0.88 : 0.3).setFill()
        NSBezierPath(roundedRect: NSRect(x: track.minX, y: track.minY, width: centerX - track.minX, height: 3), xRadius: 1.5, yRadius: 1.5).fill()
        let diameter: CGFloat = isTrackingPointer ? 10 : 7
        NSBezierPath(ovalIn: NSRect(x: centerX - diameter / 2, y: bounds.midY - diameter / 2, width: diameter, height: diameter)).fill()
    }

    override var focusRingMaskBounds: NSRect { bounds }
    override func drawFocusRingMask() {
        NSBezierPath(roundedRect: bounds, xRadius: 5, yRadius: 5).fill()
    }
}
