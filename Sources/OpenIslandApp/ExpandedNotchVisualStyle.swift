import SwiftUI

enum ExpandedNotchFontTreatment: Sendable {
    case proportional
    case monospacedDigits
    case monospaced
}

enum ExpandedNotchTypographyRole: Sendable {
    case sessionMetadata
    case elapsedLabel
    case elapsedValue
    case playbackTime
    case command

    var treatment: ExpandedNotchFontTreatment {
        switch self {
        case .sessionMetadata, .elapsedLabel:
            .proportional
        case .elapsedValue, .playbackTime:
            .monospacedDigits
        case .command:
            .monospaced
        }
    }

    var font: Font {
        switch self {
        case .sessionMetadata, .elapsedLabel:
            .caption2.weight(.medium)
        case .elapsedValue:
            .caption2.monospacedDigit().weight(.medium)
        case .playbackTime:
            .caption2.monospacedDigit()
        case .command:
            .caption.monospaced().weight(.medium)
        }
    }
}

enum ExpandedNotchTextRole: Sendable {
    case primary
    case secondary
    case tertiary
    case subdued
}

enum ExpandedNotchActionRole: Sendable {
    case primary
    case secondary
}

enum ExpandedNotchActionState: Sendable {
    case resting
    case hovered
    case pressed
    case disabled
}

enum ExpandedNotchActionFillTone: Equatable, Sendable {
    case paper
    case neutralDark
}

enum ExpandedNotchVisualStyle {
    static func textOpacity(for role: ExpandedNotchTextRole) -> Double {
        switch role {
        case .primary:
            0.92
        case .secondary:
            0.64
        case .tertiary:
            0.50
        case .subdued:
            0.40
        }
    }

    static func textColor(_ role: ExpandedNotchTextRole) -> Color {
        .white.opacity(textOpacity(for: role))
    }

    static let dividerOpacity = 0.07
    static let selectedControlFillOpacity = 0.10
    static let hoverControlFillOpacity = 0.06

    static func actionFillTone(
        for role: ExpandedNotchActionRole
    ) -> ExpandedNotchActionFillTone {
        switch role {
        case .primary:
            .paper
        case .secondary:
            .neutralDark
        }
    }

    static func actionFillOpacity(
        for role: ExpandedNotchActionRole,
        state: ExpandedNotchActionState
    ) -> Double {
        switch (role, state) {
        case (.primary, .resting):
            0.96
        case (.primary, .hovered):
            1.0
        case (.primary, .pressed):
            0.84
        case (.primary, .disabled):
            0.24
        case (.secondary, .resting):
            0.06
        case (.secondary, .hovered):
            0.10
        case (.secondary, .pressed):
            0.13
        case (.secondary, .disabled):
            0.04
        }
    }

    static func actionFillColor(
        for role: ExpandedNotchActionRole,
        state: ExpandedNotchActionState
    ) -> Color {
        let opacity = actionFillOpacity(for: role, state: state)
        switch actionFillTone(for: role) {
        case .paper:
            return V6Palette.paper.opacity(opacity)
        case .neutralDark:
            return Color.white.opacity(opacity)
        }
    }

    static func actionTextColor(
        for role: ExpandedNotchActionRole,
        state: ExpandedNotchActionState
    ) -> Color {
        if state == .disabled {
            return V6Palette.paper.opacity(0.42)
        }

        switch role {
        case .primary:
            return V6Palette.ink.opacity(0.94)
        case .secondary:
            return V6Palette.paper.opacity(0.78)
        }
    }

    static func actionStrokeOpacity(
        for role: ExpandedNotchActionRole,
        state: ExpandedNotchActionState
    ) -> Double {
        switch (role, state) {
        case (_, .disabled):
            0.06
        case (.primary, .hovered):
            0.20
        case (.primary, _):
            0.12
        case (.secondary, .hovered), (.secondary, .pressed):
            0.14
        case (.secondary, .resting):
            0.08
        }
    }
}
