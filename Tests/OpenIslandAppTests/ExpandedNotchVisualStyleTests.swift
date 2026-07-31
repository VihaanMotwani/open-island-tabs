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
}
