import AppKit
import SwiftUI

/// A compact 3×3 activity glyph shared by the closed-notch states.
///
/// The motion language is adapted from the Drive and Orbit loaders at
/// https://beautiful-ui-five.vercel.app while retaining Open Island's existing
/// state mapping, footprint, tint, and Core Animation rendering path.
struct UnifiedBars: View {
    enum Mode: Equatable {
        case idle
        case running
        case waiting

        var timelineInterval: TimeInterval? {
            nil
        }

        var usesLayerAnimation: Bool {
            switch self {
            case .idle:
                false
            case .running, .waiting:
                true
            }
        }
    }

    var mode: Mode
    var size: CGFloat = 24
    var tint: Color = Color(red: 0xf1 / 255.0, green: 0xea / 255.0, blue: 0xd9 / 255.0)
    var animationEnabled: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let box: CGFloat = 24
    private static let cellSide: CGFloat = 4
    private static let cellGap: CGFloat = 1.5

    var body: some View {
        LayerRepresentable(
            mode: mode,
            tint: tint,
            reduceMotion: reduceMotion || !animationEnabled
        )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }

    private struct LayerRepresentable: NSViewRepresentable {
        let mode: Mode
        let tint: Color
        let reduceMotion: Bool

        func makeNSView(context: Context) -> LayerView {
            let view = LayerView()
            view.update(mode: mode, tint: NSColor(tint), reduceMotion: reduceMotion)
            return view
        }

        func updateNSView(_ nsView: LayerView, context: Context) {
            nsView.update(mode: mode, tint: NSColor(tint), reduceMotion: reduceMotion)
        }
    }

    private final class LayerView: NSView {
        private let cellLayers = (0..<9).map { _ in CAShapeLayer() }
        private var mode: Mode = .idle
        private var tintColor = NSColor.white
        private var reduceMotion = false

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = CALayer()
            layer?.masksToBounds = false
            cellLayers.forEach { cellLayer in
                cellLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
                layer?.addSublayer(cellLayer)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(mode: Mode, tint: NSColor, reduceMotion: Bool) {
            self.mode = mode
            tintColor = tint
            self.reduceMotion = reduceMotion
            needsLayout = true
        }

        override func layout() {
            super.layout()
            configureLayers()
        }

        private func configureLayers() {
            let side = min(bounds.width, bounds.height)
            guard side > 0 else { return }

            let scale = side / UnifiedBars.box
            let cellSide = UnifiedBars.cellSide * scale
            let cellGap = UnifiedBars.cellGap * scale
            let gridSide = (cellSide * 3) + (cellGap * 2)
            let gridOrigin = CGPoint(
                x: (bounds.width - gridSide) / 2,
                y: (bounds.height - gridSide) / 2
            )
            let pattern = UnifiedGridPattern.make(for: mode, reduceMotion: reduceMotion)

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for (index, cell) in pattern.cells.enumerated() {
                let row = index / 3
                let column = index % 3
                let cellLayer = cellLayers[index]
                let rect = CGRect(x: 0, y: 0, width: cellSide, height: cellSide)

                cellLayer.bounds = rect
                cellLayer.position = CGPoint(
                    x: gridOrigin.x + (CGFloat(column) * (cellSide + cellGap)) + (cellSide / 2),
                    y: gridOrigin.y + (CGFloat(2 - row) * (cellSide + cellGap)) + (cellSide / 2)
                )
                cellLayer.fillColor = tintColor.cgColor
                cellLayer.path = CGPath(
                    roundedRect: rect,
                    cornerWidth: scale,
                    cornerHeight: scale,
                    transform: nil
                )
                cellLayer.opacity = cell.restingOpacity
                configureAnimation(for: cellLayer, cell: cell, duration: pattern.duration)
            }
            CATransaction.commit()
        }

        private func configureAnimation(
            for cellLayer: CAShapeLayer,
            cell: UnifiedGridPattern.Cell,
            duration: TimeInterval
        ) {
            cellLayer.removeAllAnimations()
            guard let delay = cell.delay, duration > 0 else { return }

            let animation = CAKeyframeAnimation(keyPath: "opacity")
            animation.values = [
                cell.restingOpacity,
                cell.highlightedOpacity,
                cell.highlightedOpacity,
                cell.restingOpacity,
                cell.restingOpacity,
            ]
            animation.keyTimes = [0, 0.18, 0.42, 0.62, 1]
            animation.duration = duration
            animation.beginTime = CACurrentMediaTime() + delay
            animation.repeatCount = .infinity
            animation.timingFunctions = [
                CAMediaTimingFunction(name: .easeInEaseOut),
                CAMediaTimingFunction(name: .linear),
                CAMediaTimingFunction(name: .easeInEaseOut),
                CAMediaTimingFunction(name: .linear),
            ]
            cellLayer.add(animation, forKey: "pixel-shimmer")
        }
    }
}

struct UnifiedGridPattern: Equatable {
    enum Motion: Equatable {
        case still
        case chevron
        case orbit
    }

    struct Cell: Equatable {
        let restingOpacity: Float
        let highlightedOpacity: Float
        let delay: TimeInterval?
    }

    let motion: Motion
    let duration: TimeInterval
    let cells: [Cell]

    static func make(
        for mode: UnifiedBars.Mode,
        animationEnabled: Bool = true,
        reduceMotion: Bool
    ) -> UnifiedGridPattern {
        if reduceMotion || !animationEnabled {
            return reducedMotionPattern(for: mode)
        }

        switch mode {
        case .idle:
            return stillPattern(opacities: [
                0.18, 0.30, 0.18,
                0.30, 0.58, 0.30,
                0.18, 0.30, 0.18,
            ])
        case .running:
            return animatedPattern(
                motion: .chevron,
                duration: 0.65,
                delays: [
                    0.09, 0.18, 0.27,
                    0.00, 0.09, 0.18,
                    0.09, 0.18, 0.27,
                ]
            )
        case .waiting:
            return animatedPattern(
                motion: .orbit,
                duration: 0.95,
                delays: [
                    0.00, 0.11, 0.22,
                    0.77, nil, 0.33,
                    0.66, 0.55, 0.44,
                ]
            )
        }
    }

    private static func reducedMotionPattern(for mode: UnifiedBars.Mode) -> UnifiedGridPattern {
        switch mode {
        case .idle:
            stillPattern(opacities: [
                0.18, 0.30, 0.18,
                0.30, 0.58, 0.30,
                0.18, 0.30, 0.18,
            ])
        case .running:
            stillPattern(opacities: [
                0.55, 0.28, 0.14,
                1.00, 0.55, 0.28,
                0.55, 0.28, 0.14,
            ])
        case .waiting:
            stillPattern(opacities: [
                0.52, 0.52, 0.52,
                0.52, 0.08, 0.52,
                0.52, 0.52, 0.52,
            ])
        }
    }

    private static func stillPattern(opacities: [Float]) -> UnifiedGridPattern {
        UnifiedGridPattern(
            motion: .still,
            duration: 0,
            cells: opacities.map {
                Cell(restingOpacity: $0, highlightedOpacity: $0, delay: nil)
            }
        )
    }

    private static func animatedPattern(
        motion: Motion,
        duration: TimeInterval,
        delays: [TimeInterval?]
    ) -> UnifiedGridPattern {
        UnifiedGridPattern(
            motion: motion,
            duration: duration,
            cells: delays.map { delay in
                Cell(
                    restingOpacity: delay == nil ? 0.07 : 0.15,
                    highlightedOpacity: delay == nil ? 0.07 : 1,
                    delay: delay
                )
            }
        )
    }
}
