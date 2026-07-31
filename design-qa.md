# Design QA

**Source visual truth**

- `/Users/vihaan/.codex/generated_images/019fb475-be3f-7d30-938a-742cca953924/call_kRSD7a1chySpXacn93ueD9RX.png`
- Source pixels: 1586 × 992.
- The source is a full-screen concept image rather than a density-tagged native capture.

**Rendered implementation**

- Open Spotify state: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-080516/overlay.png`
- Closed peeking-tab state, composited over black: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-080546/overlay-on-black.png`
- Implementation pixels: 1392 × 468 for a 696 × 234 point native AppKit window captured at 2× density.
- State: Spotify selected, playing, dark appearance, built-in Retina display with notch-aware placement.

**Comparison evidence**

- Full-view comparison: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-080516/reference-vs-implementation.png`
  - The source was cropped to 1360 × 500 around the notch/player.
  - The 1392 × 468 implementation capture was proportionally normalized to 1360 pixels wide before vertical comparison.
- Focused tab comparison: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-080516/tabs-reference-vs-implementation.png`
  - Equal 260 × 170 crops were placed side by side.
  - A focused comparison was required because the selected/foreground silhouette and zero-gap center seam are the core visual decision.

**Findings**

- No actionable P0, P1, or P2 differences remain.
- Fonts and typography: the implementation uses the native San Francisco system face with semibold title and medium secondary text. The scale, hierarchy, truncation, and monospaced time labels preserve the source's compact music-player hierarchy.
- Spacing and layout rhythm: artwork, metadata, progress, centered transport controls, and trailing volume control form the same left-to-right hierarchy as the source. Both tabs are the same 45 × 30 point size, overlap by 2 points, and tuck 6 points behind the notch surface. The active tab renders above its neighbor through z-order, border, fill, and shadow rather than a size change.
- Colors and visual tokens: the near-black Open Island surface, low-contrast dividers, muted secondary text, and Spotify green state color match the source direction and existing Open Island palette.
- Image quality and asset fidelity: production renders Spotify's supplied artwork with aspect-fill, a continuous rounded mask, and a subtle border. The deterministic harness intentionally has no artwork URL, so the implementation capture shows the branded Spotify fallback while preserving the exact artwork slot and crop behavior.
- Copy and content: dynamic title, artist, elapsed time, duration, and accessibility labels are present and coherent. The harness uses the same track metadata as the source concept.
- Icons and controls: native controls are optically aligned, consistently weighted, and expose Back, Forward, Pause Spotify, Spotify volume, agents, Spotify, sound, settings, and quit through accessibility.
- Interaction/state coverage: native smoke captures passed for open Spotify and closed tabs. Behavior tests cover tab selection, hover/click routing, Spotify restoration after agent interruptions, seek/volume clamping, and unavailable Spotify.

**Comparison history**

1. Initial comparison
   - [P2] Transport controls were anchored too far left in the detail column.
   - Evidence: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-074941/reference-vs-implementation.png`
   - Fix: changed the transport row to a centered layer with an independently trailing volume layer in `SpotifyPlayerView`.
2. Post-fix comparison
   - Evidence: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-075132/reference-vs-implementation.png`
   - Result: the previous left-weighted control cluster is centered and the volume control remains right aligned. No P0/P1/P2 finding remains.
3. User-directed Chrome-tab refinement
   - Changed both tabs to equal height, added curved inner contact corners, overlapped the pair by 2 points, and tucked their top shoulders 6 points behind the notch.
   - Evidence: `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-080516/tabs-reference-vs-implementation.png` and `/Users/vihaan/Documents/notch/output/harness/smoke-20260731-080546/overlay-on-black.png`.
   - Result: the selected tab comes forward through visual hierarchy only; the shared seam and notch attachment are curved with no P0/P1/P2 issue.

**Follow-up polish**

- [P3] The concept's artwork cannot appear in a deterministic no-network harness state. A live Spotify session supplies real artwork through the media adapter.
- [P3] The implementation tabs are intentionally slightly larger than the concept image, following the user's explicit request for a bigger, easier-to-hit pair.

**Implementation checklist**

- [x] Adjacent, zero-gap inverted browser tabs.
- [x] Active Spotify tab comes forward.
- [x] Wider lightweight Spotify player.
- [x] Centered playback controls and trailing volume.
- [x] Open and closed native captures.
- [x] Accessibility labels for core controls.

final result: passed
