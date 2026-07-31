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
}
