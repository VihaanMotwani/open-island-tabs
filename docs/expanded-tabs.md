# Expanded tab navigation

The expanded island and Appearance preview share `IslandTabSwitcher`: text labels
on the island background, a charcoal selection capsule, and a subtle hover fill.
The Agents attention dot is attached to its own button rather than positioned
with an offset from the entire strip. Native buttons retain keyboard activation
and accessibility labels; the selected button exposes its selected state.
Reduce Motion disables the sliding selection animation.

The display's full `islandClosedHeight` is reserved above the tab row, including
`safeAreaInsets.top` on a notched display. Do not pull the row upward into that
space. The row reserves 44 points: 4 above its 32-point buttons and 8 below.
The panel height calculation uses the same row height, so the extra navigation
space does not reduce the selected tab's content viewport. Horizontal padding
keeps the strip inside the island's curved edges; four tabs prefer 324 points.

Verify with the existing layout, tab-selection, and panel-controller tests, plus
`spotifyPlayer`, `tasksList`, `calendarAgenda`, and `approvalCard` smoke captures.
The harness report includes the real display safe-area and overlay geometry;
compare the tab position in the capture to the bottom of the physical notch. Check
switching and appearance in the refreshed development bundle as well.
