# Design QA

## Source visual truth

- User-supplied reference: `/var/folders/pb/wdsr0r1n5_v8ktxzd2_6k4740000gn/T/codex-clipboard-a5455183-f7c5-48b0-bfbc-14e541cc6a85.png`
- Source pixels: 3093 × 1740.
- Target traits: pure-black media surface; square artwork with a continuous radius; large title over quieter artist; colored waveform; elapsed and negative-remaining timeline; large centered previous, pause, and next controls; trailing output control.
- Product constraint: retain Open Island's macOS notch silhouette, persistent Agents-first tab structure, and existing playback behavior.

## Rendered implementation

- Deterministic Spotify capture: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/spotify-dynamic-island-final/overlay.png`
- Live Spotify capture: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/spotify-after-final.jpeg`
- Live volume-popover capture: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/spotify-volume-popover-final.jpeg`
- Live Agents capture: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/agents-tab-prompt-icon-final.jpeg`
- Deterministic Agents capture: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/agents-flat-status-final/overlay.png`
- Deterministic Claude launch-demo capture: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/claude-demo-verified/overlay.png`
- Deterministic approval-action capture: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/approval-off-white-final/overlay.png`
- Long-completion regression capture: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/long-completion-height-contract-184/overlay.png`
- Implementation pixels: 1200 × 512 for the deterministic 600 × 256 point Retina capture.
- State: Spotify selected and playing, dark appearance, built-in Retina display with notch-aware placement.

## Comparison evidence

- Combined reference and implementation input: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/reference-vs-spotify-final.png`
- The supplied phone image and native macOS capture are normalized to the same 1200-pixel width and placed in one vertical comparison.
- The device frames cannot share a literal viewport. Fidelity is judged on the expanded media surface's hierarchy, alignment, proportions, contrast, and control rhythm while preserving Open Island's macOS chrome.

## Findings

- No actionable P0, P1, or P2 differences remain.
- Layout: the old compact utility row is replaced by the reference's three-tier composition: artwork and metadata, full-width timeline, then centered transport controls.
- Typography: title and artist use native San Francisco semantic styles. The title is larger and high-contrast without extra-heavy display weight; the artist and time labels remain quieter.
- Color: the surface stays near-black, primary content is white, secondary metadata is gray, and Spotify green is restricted to Spotify identity and the waveform.
- Artwork: production uses Spotify's supplied artwork with aspect-fill, a 12-point continuous corner radius, a hairline edge, and a restrained shadow. The offline harness uses the real Spotify glyph fallback in the same slot.
- Controls: previous, pause, and next are larger, evenly spaced, and high-contrast. The native macOS slider deliberately keeps its thumb and accessibility behavior. Volume moves into a trailing button and native popover instead of consuming the transport row.
- Responsive behavior: the 480-point safe content width is preserved; artwork shrinks from 76 to 64 points before metadata is crowded on narrow displays.
- Agents integrity: changing tabs returns to the 500-point Agents surface without clipping or inheriting the Spotify height.
- Agents identity: the inner tabs use native 12-point caption labels with a 12.5-point SF Mono `>_` prompt, giving the control more presence without increasing its compact height.
- Agents status color: running, completed, and attention colors use a muted low-chroma palette. Status dots are flat fills with no colored shadow; the active dot retains only a restrained five-percent scale pulse. The install-hooks icon is neutral gray rather than accent blue.
- Approval actions: the primary action uses Open Island's cream-paper tone with ink text instead of warning orange. The secondary action remains neutral dark; both use semantic callout typography, compact continuous radii, pointer hover and press feedback, and accessibility-aware motion and contrast.
- Long content: completion sizing and the SwiftUI scroll viewport now share one 184-point maximum. The verified 438-point fixture shows complete visible lines and preserves the remaining text in an accessible internal scroll area.
- Interaction: the accessibility capture exposes Previous track, Pause Spotify, Next track, Spotify volume, both tabs, sound, settings, and quit. Provider tests cover seek and volume clamping.

## Comparison history

1. Baseline
   - [P2] Spotify was a 600 × 206 compact horizontal utility row with small controls, an always-visible volume slider, and no reference-like hierarchy.
   - Evidence: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/19-dynamic-island-before/spotify-before.png`.
   - Fix: rebuilt the player as a three-tier native SwiftUI surface.
2. First live pass
   - The artwork, metadata, timeline, waveform, and transport controls matched the source composition; both expanded tabs fit without clipping.
   - Evidence: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/spotify-after-final.jpeg`.
3. Cross-surface smoke pass
   - [P1] The pre-existing long completion fixture exposed a mismatched 260-point window budget and 160-point SwiftUI viewport, leaving a partially cut line above empty space.
   - Fix: introduced one shared 184-point completion-message maximum used by sizing and rendering.
   - Evidence: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/long-completion-height-contract-184/overlay.png`.
4. Final comparison
   - Raised the default transport and volume contrast to match the reference while retaining restrained hover fills.
   - Evidence: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/reference-vs-spotify-final.png`.
5. Agents-tab identity
   - Replaced the boxed terminal symbol with a direct SF Mono prompt mark so `>_` stays legible at tab scale.
   - Evidence: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/agents-prompt-icon-final/overlay.png`.
6. Agents typography and status color
   - Raised the tab labels from `caption2` to `caption`, muted the status palette, removed the static and animated colored shadows, and neutralized the install-hooks icon.
   - Evidence: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/agents-flat-status-final/overlay.png`.
7. Claude launch-demo surface
   - Added a local-only fixture with two running Claude sessions, one completed session, two subagents, and three task states. The synthetic sessions suppress the real hook-setup prompt and remain fully visible in the expanded notch.
   - The recording launcher uses a separately identified temporary app bundle, so it does not collide with or replace the normal development app.
   - Evidence: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/claude-demo-verified/overlay.png`; the same surface was verified live in `Open Island Claude Demo`.
8. Approval action styling
   - Replaced the amber permission CTA with the existing cream-paper system, kept Deny visually secondary, reduced the radius and vertical padding, and added restrained hover and press feedback.
   - The final 500 × 326 point fixture contains the full command preview and all actions; the AX capture exposes Allow and Deny as buttons. The same surface was inspected live in a separately identified local preview app.
   - Evidence: `/Users/vihaan/.codex/worktrees/a54d/notch/output/harness/approval-off-white-final/overlay.png`.

## Intentional platform adaptations

- The Agents/Spotify tab switcher and header controls remain because they are core Open Island navigation, not part of the phone reference.
- The trailing control opens the existing Spotify volume behavior rather than presenting a non-functional AirPlay glyph.
- Native macOS slider, hover, popover, and accessibility behavior take precedence over reproducing iOS controls literally.

final result: passed

---

# README Banner Design QA

## Comparison target

- Source visual truth: `/Users/vihaan/.codex/generated_images/019fb6d5-150b-7ef0-900e-3daa5206e134/exec-91b9ad5d-3caf-4661-bc2e-6671d4a77c54.png`
- Checked-in implementation: `docs/images/readme-banner.png`
- Combined comparison evidence: `/tmp/readme-banner-comparison.png` (source left, implementation right)
- State: static GitHub README hero
- Intended viewport: 1024 x 384 CSS px via the README `width="1024"` image attribute
- Source pixels: 2048 x 768
- Implementation pixels: 2048 x 768
- Density normalization: both files are pixel-identical 2x assets displayed at 1024 x 384 CSS px

## Findings

- No P0, P1, or P2 differences found.
- Fonts and typography: exact raster match; headline, supporting line, and UI labels retain the selected visual's weight, spacing, and antialiasing.
- Spacing and layout rhythm: exact raster match; silhouette proportions, internal divisions, notification, Agents area, music area, and lower copy remain aligned.
- Colors and visual tokens: exact raster match; warm graphite background, cream text, muted status accents, and subtle path lighting are unchanged.
- Image quality and asset fidelity: the checked-in PNG has the same SHA-256 digest as the selected source and keeps the original 2048 x 768 resolution without recompression.
- Copy and content: exact raster match; `Stay in flow.` and `Agents and music. One glance away.` are preserved.

## Focused comparison

A separate crop comparison was not needed because the source and implementation have identical dimensions and SHA-256 digests. The original-resolution full-view comparison keeps the small session labels and transport controls readable enough to verify.

## Comparison history

- First pass: no actionable P0/P1/P2 mismatch; no visual fix was required.

## Implementation checklist

- [x] Use the selected generated banner without redraw or approximation.
- [x] Preserve its 8:3 aspect ratio at a GitHub-friendly 1024 px display width.
- [x] Point both English and Chinese READMEs at the new banner.
- [x] Keep fork ownership and upstream attribution outside the image as accessible README text.

## Follow-up polish

- None required for fidelity. A future iteration could replace synthetic session copy with a newly generated privacy-neutral variant if desired.

final result: passed

---

# macIsland UI Design QA

## Reference

- AyushmanMalla/macIsland at commit `7f8a6efb3a28e7c85efee973184c811e457306a6`
- Local reference bundle: `/Users/vihaan/Downloads/macIsland.app.zip`
- Source measurements verified directly against `ExpandedIslandLayout.swift`,
  `ExpandedIslandView.swift`, `MusicTabView.swift`, `TasksView.swift`, and
  `TaskRowView.swift`
- The source tab control is a native small segmented `Picker`, 144 points wide
  for two 72-point text segments, with a 0.30-second snappy transition.
- Open Island adapts that exact native control to three 72-point text segments:
  Agents, Spotify, and To-do.

The reference app was not relaunched after the forced reference harness caused
its screen-sized transparent panel to remain interactive. Final QA deliberately
uses Open Island's bounded deterministic harness instead.

## Captures checked

- Spotify: `output/harness/header-insets/spotifyPlayer/overlay.png` — 443 x 214 points
- To-do: `output/harness/header-insets/tasksList/overlay.png` — 446 x 360 points
- Agents: `output/harness/header-insets/sessionList/overlay.png` — 486 x 296 points
- Approval: `output/harness/macisland-motion/approvalCard/overlay.png` — 486 x 321 points
- Before/after tab-chrome comparison:
  `output/harness/macisland-motion/spotify-tabs-before-after.png`

## Visual and behavior checks

- Unified black surface stretches through the physical-notch header.
- Mute, settings, and quit remain visible in the physical notch's right wing on
  all three panel widths. Width calculations reserve the complete 82-point
  control group instead of allowing the hardware notch to occlude it.
- Usage and header controls share the same 30-point horizontal content inset,
  so neither cluster sits against the concave silhouette edge. Compact tabs
  widen only when the hardware-notch clearance requires it.
- Agent usage is rendered only when Agents is selected; Spotify and To-do
  captures contain no usage percentage or provider chip.
- The previous custom icon-and-label Open Island tabs are gone. Tabs now use
  macIsland's native small segmented `Picker`, with text-only segments and the
  platform-selected fill.
- Forward selection slides content in from the trailing edge; backward selection
  slides it in from the leading edge. Panel width and height animate over the
  same 0.30-second interval instead of snapping between tab sizes.
- Spotify uses 68-point artwork, a 15-point radius, centered title and artist,
  source-matched transport sizing, a thin seek control, and a volume popover.
- To-do uses the source-matched checklist field, 36-point input, 34-point rows,
  8-point row spacing, 12-point radii, context-menu edit/delete, completion
  ordering, and five fully visible rows before scrolling.
- Agents keep compact expandable rows, dedicated jump controls, timers,
  grouping, approvals, questions, replies, and auto-expanded actionable content.
- Agents, Spotify, and To-do use different bounded panel sizes.
- Closed hit testing no longer extends into a hidden peeking-tab strip, and a
  closed click no longer pins the island open.
- Reduced Motion disables the custom spring/blur/scale transitions.

## Safety and accessibility

- Every deterministic overlay remained between 426 and 486 points wide; no
  screen-sized interactive window is used.
- Harness accessibility snapshots expose all tabs, transport buttons, task
  completion controls, header controls, jump controls, and approval actions.
- Reduced Motion disables both directional content movement and AppKit panel
  resizing while keeping a simple opacity change.

final result: passed
