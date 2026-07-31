import AppKit
import SwiftUI

/// Four-column music equalizer adapted from Amicro's MIT-licensed Apple EQ:
/// https://github.com/Subhan-code/Amicro--Micro-transitions-/blob/main/registry/ui/loading/apple-equalizer.tsx
struct MediaActivityIndicator: View {
    let state: MediaActivityState
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isPlaying: Bool {
        state == .playing
    }

    var body: some View {
        Button(action: action) {
            EqualizerLayerRepresentable(
                state: state,
                reduceMotion: reduceMotion,
                tint: V6Palette.paper
            )
            .frame(width: 18, height: 18)
            .accessibilityHidden(true)
        }
        .buttonStyle(.plain)
        .contentShape(Rectangle())
        .help(isPlaying ? "Spotify is playing" : "Spotify is paused")
        .accessibilityLabel("Spotify")
        .accessibilityValue(isPlaying ? "Playing" : "Paused")
        .accessibilityHint("Opens Spotify controls")
    }

    private struct EqualizerLayerRepresentable: NSViewRepresentable {
        let state: MediaActivityState
        let reduceMotion: Bool
        let tint: Color

        func makeNSView(context: Context) -> EqualizerLayerView {
            let view = EqualizerLayerView()
            view.update(
                state: state,
                reduceMotion: reduceMotion,
                tint: NSColor(tint)
            )
            return view
        }

        func updateNSView(_ nsView: EqualizerLayerView, context: Context) {
            nsView.update(
                state: state,
                reduceMotion: reduceMotion,
                tint: NSColor(tint)
            )
        }
    }

    private final class EqualizerLayerView: NSView {
        private static let box: CGFloat = 18
        private static let barWidth: CGFloat = 3
        private static let barGap: CGFloat = 1.5
        private static let maxBarHeight: CGFloat = 13
        private static let bottomInset: CGFloat = 2.5

        private let barLayers = (0..<4).map { _ in CAShapeLayer() }
        private var state: MediaActivityState = .paused
        private var reduceMotion = false
        private var tintColor = NSColor.white

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = CALayer()
            layer?.masksToBounds = false
            barLayers.forEach { barLayer in
                barLayer.anchorPoint = CGPoint(x: 0.5, y: 0)
                barLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2
                layer?.addSublayer(barLayer)
            }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        func update(
            state: MediaActivityState,
            reduceMotion: Bool,
            tint: NSColor
        ) {
            self.state = state
            self.reduceMotion = reduceMotion
            tintColor = tint
            needsLayout = true
        }

        override func layout() {
            super.layout()
            configureLayers()
        }

        private func configureLayers() {
            let side = min(bounds.width, bounds.height)
            guard side > 0 else { return }

            let scale = side / Self.box
            let barWidth = Self.barWidth * scale
            let barGap = Self.barGap * scale
            let barHeight = Self.maxBarHeight * scale
            let totalWidth = (barWidth * 4) + (barGap * 3)
            let originX = (bounds.width - totalWidth) / 2
            let originY = ((bounds.height - side) / 2) + (Self.bottomInset * scale)
            let pattern = MediaEqualizerPattern.make(
                for: state,
                reduceMotion: reduceMotion
            )

            CATransaction.begin()
            CATransaction.setDisableActions(true)
            for (index, bar) in pattern.bars.enumerated() {
                let barLayer = barLayers[index]
                let rect = CGRect(x: 0, y: 0, width: barWidth, height: barHeight)

                barLayer.bounds = rect
                barLayer.position = CGPoint(
                    x: originX + (CGFloat(index) * (barWidth + barGap)) + (barWidth / 2),
                    y: originY
                )
                barLayer.fillColor = tintColor.cgColor
                barLayer.path = topRoundedBarPath(
                    in: rect,
                    radius: min(barWidth / 2, 1.25 * scale)
                )
                barLayer.opacity = state == .playing ? 0.94 : 0.42
                barLayer.transform = CATransform3DMakeScale(1, bar.restingScale, 1)
                configureAnimation(
                    for: barLayer,
                    bar: bar,
                    duration: pattern.duration
                )
            }
            CATransaction.commit()
        }

        private func configureAnimation(
            for barLayer: CAShapeLayer,
            bar: MediaEqualizerPattern.Bar,
            duration: TimeInterval
        ) {
            barLayer.removeAllAnimations()
            guard let delay = bar.delay, duration > 0 else { return }

            let animation = CAKeyframeAnimation(keyPath: "transform.scale.y")
            animation.values = [bar.restingScale, bar.peakScale, bar.restingScale]
            animation.keyTimes = [0, 0.5, 1]
            animation.duration = duration
            animation.beginTime = CACurrentMediaTime() + delay
            animation.repeatCount = .infinity
            animation.timingFunctions = [
                CAMediaTimingFunction(controlPoints: 0.85, 0, 0.15, 1),
                CAMediaTimingFunction(controlPoints: 0.85, 0, 0.15, 1),
            ]
            barLayer.add(animation, forKey: "music-equalizer")
        }

        private func topRoundedBarPath(in rect: CGRect, radius: CGFloat) -> CGPath {
            let path = CGMutablePath()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - radius))
            path.addQuadCurve(
                to: CGPoint(x: rect.minX + radius, y: rect.maxY),
                control: CGPoint(x: rect.minX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
            path.addQuadCurve(
                to: CGPoint(x: rect.maxX, y: rect.maxY - radius),
                control: CGPoint(x: rect.maxX, y: rect.maxY)
            )
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.closeSubpath()
            return path
        }
    }
}

struct MediaEqualizerPattern: Equatable {
    enum Motion: Equatable {
        case still
        case equalizing
    }

    struct Bar: Equatable {
        let restingScale: CGFloat
        let peakScale: CGFloat
        let delay: TimeInterval?
    }

    let motion: Motion
    let duration: TimeInterval
    let bars: [Bar]

    static func make(
        for state: MediaActivityState,
        reduceMotion: Bool
    ) -> MediaEqualizerPattern {
        switch state {
        case .hidden:
            return still(scales: [0, 0, 0, 0])
        case .paused:
            return still(scales: [0.20, 0.76, 0.58, 0.82])
        case .playing where reduceMotion:
            return still(scales: [0.36, 0.82, 0.56, 0.72])
        case .playing:
            return MediaEqualizerPattern(
                motion: .equalizing,
                duration: 0.8,
                bars: [0.00, 0.13, 0.26, 0.39].map { delay in
                    Bar(restingScale: 0.20, peakScale: 1.00, delay: delay)
                }
            )
        }
    }

    private static func still(scales: [CGFloat]) -> MediaEqualizerPattern {
        MediaEqualizerPattern(
            motion: .still,
            duration: 0,
            bars: scales.map {
                Bar(restingScale: $0, peakScale: $0, delay: nil)
            }
        )
    }
}
