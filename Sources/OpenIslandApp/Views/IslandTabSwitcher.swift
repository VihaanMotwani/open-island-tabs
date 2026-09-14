import SwiftUI

/// A shared tab strip for the live island and its appearance preview.
/// The parent reserves the display's full notch height above this row.
struct IslandTabSwitcher: View {
    let tabs: [IslandTab]
    @Binding var selection: IslandTab
    var showsAgentAttention = false
    let title: (IslandTab) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorSchemeContrast) private var contrast
    @Namespace private var selectionNamespace
    @State private var hoveredTab: IslandTab?

    var body: some View {
        HStack(spacing: ExpandedNotchLayoutMetrics.tabSpacing) {
            ForEach(tabs) { tab in
                Button {
                    selection = tab
                } label: {
                    Text(title(tab))
                        .font(.callout.weight(.medium))
                        .foregroundStyle(ExpandedNotchVisualStyle.textColor(
                            selection == tab || contrast == .increased ? .primary : .secondary
                        ))
                        .lineLimit(1)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity)
                        .frame(height: ExpandedNotchLayoutMetrics.tabControlHeight)
                        .background {
                            if selection == tab {
                                Capsule()
                                    .fill(.white.opacity(contrast == .increased ? 0.22 : 0.12))
                                    .matchedGeometryEffect(id: "selection", in: selectionNamespace)
                            } else if hoveredTab == tab {
                                Capsule()
                                    .fill(.white.opacity(ExpandedNotchVisualStyle.hoverControlFillOpacity))
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if tab == .agents && showsAgentAttention {
                                Circle()
                                    .fill(IslandDesignPalette.Status.waitingAggregate)
                                    .frame(width: 5, height: 5)
                                    .padding(5)
                                    .accessibilityHidden(true)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .onHover { hoveredTab = $0 ? tab : nil }
                .accessibilityLabel(title(tab))
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .frame(maxWidth: ExpandedNotchLayoutMetrics.tabSegmentedControlWidth(visibleTabCount: tabs.count))
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.20), value: selection)
        .padding(.top, ExpandedNotchLayoutMetrics.tabTopPadding)
        .frame(maxWidth: .infinity)
        .frame(height: ExpandedNotchLayoutMetrics.tabSwitcherHeight, alignment: .top)
        .accessibilityElement(children: .contain)
    }
}
