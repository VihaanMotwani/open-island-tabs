import AppKit

/// Original geometric artwork for deterministic UI checks; never downloads a cover.
enum MusicPreviewArtwork {
    static func image(alternate: Bool = false) -> NSImage {
        NSImage(size: NSSize(width: 256, height: 256), flipped: false) { bounds in
            let colors: [NSColor] = alternate
                ? [.init(red: 0.1, green: 0.25, blue: 0.48, alpha: 1), .init(red: 0.45, green: 0.72, blue: 0.75, alpha: 1)]
                : [.init(red: 0.28, green: 0.17, blue: 0.4, alpha: 1), .init(red: 0.92, green: 0.45, blue: 0.28, alpha: 1)]
            NSGradient(colors: colors)?.draw(in: bounds, angle: 45)
            NSColor.white.withAlphaComponent(0.2).setFill()
            NSBezierPath(ovalIn: NSRect(x: alternate ? 18 : 100, y: 80, width: 150, height: 150)).fill()
            NSColor.black.withAlphaComponent(0.4).setFill()
            let path = NSBezierPath()
            path.move(to: NSPoint(x: 0, y: 0))
            path.line(to: NSPoint(x: 256, y: 0))
            path.line(to: NSPoint(x: 256, y: 75))
            path.line(to: NSPoint(x: 110, y: 150))
            path.line(to: NSPoint(x: 0, y: 105))
            path.close()
            path.fill()
            return true
        }
    }
}
