import Testing
@testable import OpenIslandApp

struct ExpandedNotchVisualStyleTests {
    @Test
    func readableMetadataReservesMonospacingForChangingValuesAndCode() {
        #expect(ExpandedNotchTypographyRole.sessionMetadata.treatment == .proportional)
        #expect(ExpandedNotchTypographyRole.elapsedLabel.treatment == .proportional)
        #expect(ExpandedNotchTypographyRole.elapsedValue.treatment == .monospacedDigits)
        #expect(ExpandedNotchTypographyRole.playbackTime.treatment == .monospacedDigits)
        #expect(ExpandedNotchTypographyRole.command.treatment == .monospaced)
    }

    @Test
    func neutralHierarchyKeepsSmallTextLegibleOnTheBlackIsland() {
        let primary = ExpandedNotchVisualStyle.textOpacity(for: .primary)
        let secondary = ExpandedNotchVisualStyle.textOpacity(for: .secondary)
        let tertiary = ExpandedNotchVisualStyle.textOpacity(for: .tertiary)
        let subdued = ExpandedNotchVisualStyle.textOpacity(for: .subdued)

        #expect(primary >= 0.90)
        #expect(secondary >= 0.60)
        #expect(tertiary >= 0.48)
        #expect(subdued >= 0.38)
        #expect(primary > secondary)
        #expect(secondary > tertiary)
        #expect(tertiary > subdued)
    }

    @Test
    func approvalActionsUseNeutralPaperAndDarkTonesWithPointerFeedback() {
        #expect(ExpandedNotchVisualStyle.actionFillTone(for: .primary) == .paper)
        #expect(ExpandedNotchVisualStyle.actionFillTone(for: .secondary) == .neutralDark)

        let primaryResting = ExpandedNotchVisualStyle.actionFillOpacity(
            for: .primary,
            state: .resting
        )
        let primaryHovered = ExpandedNotchVisualStyle.actionFillOpacity(
            for: .primary,
            state: .hovered
        )
        let primaryPressed = ExpandedNotchVisualStyle.actionFillOpacity(
            for: .primary,
            state: .pressed
        )
        let secondaryResting = ExpandedNotchVisualStyle.actionFillOpacity(
            for: .secondary,
            state: .resting
        )
        let secondaryHovered = ExpandedNotchVisualStyle.actionFillOpacity(
            for: .secondary,
            state: .hovered
        )

        #expect(primaryResting >= 0.92)
        #expect(primaryHovered > primaryResting)
        #expect(primaryPressed < primaryResting)
        #expect(secondaryResting <= 0.07)
        #expect(secondaryHovered > secondaryResting)
    }
}
