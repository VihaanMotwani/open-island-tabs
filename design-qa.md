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
- Live Agents capture: `/Users/vihaan/.codex/visualizations/2026/07/31/019fb6d5-150b-7ef0-900e-3daa5206e134/open-island-expanded-notch-audit/20-dynamic-island-after/agents-after-final.jpeg`
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

## Intentional platform adaptations

- The Agents/Spotify tab switcher and header controls remain because they are core Open Island navigation, not part of the phone reference.
- The trailing control opens the existing Spotify volume behavior rather than presenting a non-functional AirPlay glyph.
- Native macOS slider, hover, popover, and accessibility behavior take precedence over reproducing iOS controls literally.

final result: passed
