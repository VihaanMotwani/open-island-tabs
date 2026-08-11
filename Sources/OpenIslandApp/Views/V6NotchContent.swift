import SwiftUI
import OpenIslandCore

/// Per-cell state for the closed-island agents grid. Drives tile rendering:
/// running = full color, idle = dim, waiting = opacity pulse.
enum AgentGridCellState: Equatable {
    case running
    case idle
    case waiting
}

/// One cell in the closed-island agents grid. `.session` carries the agent
/// tool's brand color and its current state. `.overflow` is a single trailing
/// cell shown when there are more sessions than the grid can display.
enum AgentGridCell: Equatable {
    case session(color: Color, state: AgentGridCellState)
    case overflow(Int)
}

/// Concrete payload for the closed island's right slot. The `AppModel`
/// computes one of these from live session state according to the user's
/// `islandRightSlot` preference; the view side is agnostic to which
/// setting produced it.
enum IslandRightSlotContent: Equatable {
    case count(Int)              // "×N" badge
    case agents([AgentGridCell]) // balanced grid, one tile per session
}

// MARK: - Right-slot renderers

struct V6RightSlotView: View {
    let content: IslandRightSlotContent

    var body: some View {
        switch content {
        case .count(let n):
            Text("×\(n)")
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .foregroundStyle(V6Palette.paper.opacity(0.72))
        case .agents(let cells):
            AgentsGridBody(cells: cells)
        }
    }

    /// Intrinsic width used by the fluid-layout math. Values are slightly
    /// padded beyond the raw text measurement so the pill always reserves
    /// enough room for the `.fixedSize()` content to render on one line,
    /// without HStack compression forcing a wrap.
    static func intrinsicWidth(of content: IslandRightSlotContent) -> CGFloat {
        switch content {
        case .count(let n):
            let digits = Double(max(1, String(n).count))
            // "×" + digits at 11pt mono ≈ 7.2pt/char.
            return CGFloat(14.4 + max(0.0, digits - 1.0) * 7.2)
        case .agents(let cells):
            let n = cells.count
            guard n > 0 else { return 0 }
            let rows = balancedRows(n)
            let maxRow = rows.max() ?? 0
            let geom = cellGeometry(rowCount: rows.count)
            return CGFloat(maxRow) * geom.cell + CGFloat(max(0, maxRow - 1)) * geom.gap
        }
    }

    // MARK: Balanced layout algorithm
    //
    // For each n from 1 to 9, we hand-tune the per-row cell counts so the
    // matrix reads as a deliberate shape instead of a wrap-at-4-columns grid.
    // For n >= 10 the AppModel caps the list at 7 sessions + 1 overflow cell,
    // which lays out as [4,4] — so balancedRows(8) is what actually renders
    // for all high-count cases in production.
    static func balancedRows(_ n: Int) -> [Int] {
        switch n {
        case ..<1: return []
        case 1: return [1]
        case 2: return [2]
        case 3: return [3]
        case 4: return [2, 2]
        case 5: return [3, 2]
        case 6: return [3, 3]
        case 7: return [4, 3]
        case 8: return [4, 4]
        case 9: return [3, 3, 3]
        default: return [4, 4]
        }
    }

    /// Cell size shrinks when the matrix has 3 rows so total height still
    /// fits inside the pill's internal vertical budget (~20pt).
    static func cellGeometry(rowCount: Int) -> (cell: CGFloat, gap: CGFloat, radius: CGFloat) {
        if rowCount >= 3 { return (cell: 6, gap: 1.5, radius: 1.0) }
        return (cell: 8, gap: 2, radius: 1.5)
    }

    static func splitIntoRows(_ cells: [AgentGridCell], rowSizes: [Int]) -> [[AgentGridCell]] {
        var out: [[AgentGridCell]] = []
        var idx = 0
        for size in rowSizes {
            let end = min(idx + size, cells.count)
            out.append(Array(cells[idx..<end]))
            idx = end
            if idx >= cells.count { break }
        }
        return out
    }
}

// MARK: - Agents grid body

/// V1a Dense Grid renderer. 2D matrix of 8×8 rounded squares (6×6 when 3 rows),
/// each row horizontally centered around the widest row. Running = full color,
/// idle = 22% alpha, waiting = opacity 0.35 ↔ 1 breathing pulse.
private struct AgentsGridBody: View {
    let cells: [AgentGridCell]

    var body: some View {
        let rowSizes = V6RightSlotView.balancedRows(cells.count)
        let geom = V6RightSlotView.cellGeometry(rowCount: rowSizes.count)
        let rows = V6RightSlotView.splitIntoRows(cells, rowSizes: rowSizes)

        VStack(spacing: geom.gap) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: geom.gap) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, cell in
                        AgentsGridTileView(cell: cell, size: geom.cell, radius: geom.radius)
                    }
                }
            }
        }
        .fixedSize()
    }
}

private struct AgentsGridTileView: View {
    let cell: AgentGridCell
    let size: CGFloat
    let radius: CGFloat

    var body: some View {
        switch cell {
        case .session(let color, let state):
            switch state {
            case .running:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color)
                    .frame(width: size, height: size)
            case .idle:
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(color.opacity(0.22))
                    .frame(width: size, height: size)
            case .waiting:
                AgentsGridWaitingTile(color: color, size: size, radius: radius)
            }
        case .overflow(let n):
            ZStack {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(V6Palette.paper.opacity(0.14))
                Text("+\(n)")
                    .font(.system(size: max(5, size * 0.55), weight: .bold, design: .monospaced))
                    .foregroundStyle(V6Palette.paper)
            }
            .frame(width: size, height: size)
        }
    }
}

private struct AgentsGridWaitingTile: View {
    let color: Color
    let size: CGFloat
    let radius: CGFloat
    @State private var pulse = false

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(color)
            .frame(width: size, height: size)
            .opacity(pulse ? 1.0 : 0.35)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
    }
}

// MARK: - Center label renderer

struct V6CenterLabelView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 11.5, weight: .medium, design: .monospaced))
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(V6Palette.paper)
    }

    static func intrinsicWidth(of text: String) -> CGFloat {
        CGFloat(Double(text.count) * 7.3 + 10)
    }
}

// MARK: - Closed-pill layouts

struct V6ClosedPillGeometry: Equatable {
    static let innerGap: CGFloat = 6

    let width: CGFloat
    let height: CGFloat
    let horizontalOffset: CGFloat
    let leadingReserve: CGFloat
    let trailingReserve: CGFloat

    @MainActor
    static func resolve(
        label: String?,
        rightSlot: IslandRightSlotContent?,
        mediaActivity: MediaActivityState,
        layout: V6ClosedLayout,
        height: CGFloat,
        physicalNotchWidth: CGFloat,
        minWidth: CGFloat
    ) -> V6ClosedPillGeometry {
        let mediaActivityWidth: CGFloat = mediaActivity == .hidden ? 0 : 21
        let leadingWidth = V6MacBookSlotMetrics.leadingActivityContentWidth(
            mediaActivityWidth: mediaActivityWidth
        )

        switch layout {
        case .external:
            let labelWidth = label.map { V6CenterLabelView.intrinsicWidth(of: $0) } ?? 0
            let rightWidth = rightSlot.map { V6RightSlotView.intrinsicWidth(of: $0) } ?? 0
            let labelBlock = label == nil ? 0 : Self.innerGap + labelWidth
            let rightBlock = rightSlot == nil ? 0 : Self.innerGap + rightWidth
            let intrinsicWidth = height + leadingWidth + labelBlock + rightBlock

            return V6ClosedPillGeometry(
                width: max(minWidth, intrinsicWidth),
                height: height,
                horizontalOffset: 0,
                leadingReserve: 0,
                trailingReserve: 0
            )
        case .macbook:
            let trailingWidth = rightSlot.map { V6RightSlotView.intrinsicWidth(of: $0) } ?? 0
            let leadingReserve = V6MacBookSlotMetrics.leadingReserve(
                contentWidth: leadingWidth
            )
            let trailingReserve = V6MacBookSlotMetrics.trailingReserve(
                contentWidth: trailingWidth
            )

            return V6ClosedPillGeometry(
                width: leadingReserve + physicalNotchWidth + trailingReserve,
                height: height,
                horizontalOffset: V6MacBookSlotMetrics.hardwareAlignmentOffset(
                    leadingReserve: leadingReserve,
                    trailingReserve: trailingReserve
                ),
                leadingReserve: leadingReserve,
                trailingReserve: trailingReserve
            )
        }
    }
}

/// The canonical v6 closed-island pill rendered inside a fixed-height frame.
/// Pure view — takes all parameters explicitly so it can be reused for the
/// live settings preview and the real island.
struct V6ClosedPill: View {
    var mode: UnifiedBars.Mode
    var label: String?          // suppressed automatically in MacBook layout
    var rightSlot: IslandRightSlotContent?
    var mediaActivity: MediaActivityState = .hidden
    var onMediaActivitySelected: (() -> Void)?
    var layout: V6ClosedLayout
    var height: CGFloat = 32

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// MacBook mode only — width of the physical notch cutout to wrap.
    var physicalNotchWidth: CGFloat = 0

    /// External mode only — minimum pill width (locked). Defaults to the
    /// width that fits just the glyph.
    var minWidth: CGFloat = 70

    var body: some View {
        switch layout {
        case .external: externalBody
        case .macbook:  macbookBody
        }
    }

    private var geometry: V6ClosedPillGeometry {
        V6ClosedPillGeometry.resolve(
            label: label,
            rightSlot: rightSlot,
            mediaActivity: mediaActivity,
            layout: layout,
            height: height,
            physicalNotchWidth: physicalNotchWidth,
            minWidth: minWidth
        )
    }

    @ViewBuilder
    private var leadingActivityCluster: some View {
        HStack(spacing: V6MacBookSlotMetrics.leadingActivitySpacing) {
            if mediaActivity != .hidden {
                MediaActivityIndicator(
                    state: mediaActivity,
                    action: onMediaActivitySelected ?? {}
                )
                .transition(.opacity.combined(with: .scale(scale: 0.82)))
            }

            UnifiedBars(mode: mode, size: 24)
                .frame(width: 24, height: 24)
        }
    }

    // MARK: External (fluid)

    private var externalBody: some View {
        return ZStack {
            V6ClosedPillShape()
                .fill(V6Palette.ink)

            HStack(spacing: 0) {
                leadingActivityCluster

                if let label {
                    V6CenterLabelView(text: label)
                        .padding(.leading, V6ClosedPillGeometry.innerGap)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                }

                Spacer(minLength: V6ClosedPillGeometry.innerGap)

                if let rightSlot {
                    V6RightSlotView(content: rightSlot)
                        .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(.horizontal, height / 2)
        }
        .frame(width: geometry.width, height: geometry.height)
        .animation(
            .timingCurve(0.4, 0, 0.2, 1, duration: 0.45),
            value: AnyHashable([
                AnyHashable(label ?? ""),
                AnyHashable(rightSlot.map(RightSlotKey.init) ?? .none),
                AnyHashable(mode),
            ])
        )
        .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: mediaActivity)
    }

    // MARK: MacBook (content-balanced around the physical notch)

    private var macbookBody: some View {
        return ZStack {
            V6ClosedPillShape()
                .fill(V6Palette.ink)

            HStack(spacing: 0) {
                leadingActivityCluster
                    .padding(.leading, V6MacBookSlotMetrics.outerEdgeInset)
                    .padding(.trailing, V6MacBookSlotMetrics.leadingNotchGap)
                    .frame(width: geometry.leadingReserve, alignment: .trailing)

                Color.clear
                    .frame(width: physicalNotchWidth)

                ZStack(alignment: .leading) {
                    if let rightSlot {
                        V6RightSlotView(content: rightSlot)
                    }
                }
                .frame(width: geometry.trailingReserve, height: height, alignment: .center)
            }
        }
        .frame(width: geometry.width, height: geometry.height)
        .offset(x: geometry.horizontalOffset)
        .animation(reduceMotion ? nil : .smooth(duration: 0.28), value: mediaActivity)
    }
}

enum V6ClosedLayout: Equatable {
    case external
    case macbook
}

struct V6MacBookSlotMetrics {
    static let outerEdgeInset: CGFloat = 12
    static let leadingActivitySpacing: CGFloat = 9
    static let leadingNotchGap: CGFloat = 8
    static let trailingNotchGap: CGFloat = 12

    static func leadingActivityContentWidth(
        mediaActivityWidth: CGFloat
    ) -> CGFloat {
        let spacing = mediaActivityWidth > 0 ? leadingActivitySpacing : 0
        return mediaActivityWidth + spacing + 24
    }

    static func leadingReserve(contentWidth: CGFloat) -> CGFloat {
        outerEdgeInset + contentWidth + leadingNotchGap
    }

    static func trailingReserve(contentWidth: CGFloat) -> CGFloat {
        trailingNotchGap + contentWidth + outerEdgeInset
    }

    static func leadingContentOrigin(
        notchLeft: CGFloat,
        reserve: CGFloat
    ) -> CGFloat {
        leadingSurfaceOrigin(notchLeft: notchLeft, reserve: reserve)
            + outerEdgeInset
    }

    static func leadingSurfaceOrigin(
        notchLeft: CGFloat,
        reserve: CGFloat
    ) -> CGFloat {
        notchLeft - reserve
    }

    static func leadingGridOrigin(
        notchLeft: CGFloat,
        reserve: CGFloat,
        mediaActivityWidth: CGFloat
    ) -> CGFloat {
        let spacing = mediaActivityWidth > 0 ? leadingActivitySpacing : 0
        return leadingContentOrigin(notchLeft: notchLeft, reserve: reserve)
            + mediaActivityWidth
            + spacing
    }

    static func trailingContentOrigin(
        notchRight: CGFloat,
        reserve: CGFloat,
        contentWidth: CGFloat
    ) -> CGFloat {
        notchRight + ((reserve - contentWidth) / 2)
    }

    static func trailingContentCenter(
        notchRight: CGFloat,
        reserve: CGFloat
    ) -> CGFloat {
        notchRight + (reserve / 2)
    }

    /// The closed pill has independently sized left and right wings. When
    /// SwiftUI centers the pill's outer bounds, that asymmetry would move the
    /// transparent notch span away from the hardware notch. Shift the visual
    /// surface so the center of the transparent span remains screen-centered.
    static func hardwareAlignmentOffset(
        leadingReserve: CGFloat,
        trailingReserve: CGFloat
    ) -> CGFloat {
        (trailingReserve - leadingReserve) / 2
    }
}

struct V6ClosedSurfaceMetrics {
    static let externalDisplayWidth: CGFloat = 360

    static func maximumNotchedWidth(notchWidth: CGFloat) -> CGFloat {
        let maximumLeadingContentWidth =
            V6MacBookSlotMetrics.leadingActivityContentWidth(
                mediaActivityWidth: 21
            )
        let maximumWingReserve = V6MacBookSlotMetrics.leadingReserve(
            contentWidth: maximumLeadingContentWidth
        )
        return notchWidth + (maximumWingReserve * 2)
    }
}

private enum RightSlotKey: Hashable {
    case count(Int)
    case agents(Int)

    init(_ content: IslandRightSlotContent) {
        switch content {
        case .count(let n):    self = .count(n)
        case .agents(let cs):  self = .agents(cs.count)
        }
    }
}

// MARK: - Settings-tab live preview

/// Fixed-width pill that mimics the real island inside the settings-tab
/// preview stage. Parameters match what the tab exposes.
struct IslandPreviewPill: View {
    let mode: UnifiedBars.Mode
    let label: String?
    let rightSlot: IslandRightSlotContent?
    let layout: V6ClosedLayout
    let physicalNotchWidth: CGFloat
    let now: Date

    var body: some View {
        V6ClosedPill(
            mode: mode,
            label: label,
            rightSlot: rightSlot,
            layout: layout,
            physicalNotchWidth: physicalNotchWidth
        )
        .frame(maxWidth: .infinity, alignment: .center)
    }
}
