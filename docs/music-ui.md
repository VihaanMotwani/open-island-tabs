# Music presentation

The Spotify tab uses an artwork-led player with left-aligned song information,
a seek bar with elapsed and total time, transport controls, and volume.
Spotify remains the playback provider; this change adds no music services.

The compact notch, track-change preview, and expanded player share one artwork
presentation. A track's cover and labels arrive together, retaining the previous
pair while loading. Requests time out, failed images resolve to a music-note
placeholder, and superseded results cannot replace a newer selection. A small
in-memory image cache avoids repeated downloads when revisiting tracks.

Artwork shares a geometry namespace across compact and expanded states, adapted
from Boring Notch. Cover and label changes use a short fade and vertical motion.
Reduce Motion disables decorative movement. Existing agent alerts and manually
opened tabs retain priority over the 2.2-second track-change preview.

## Attribution

Adapted from TheBoredTeam's [Boring Notch at 99900bf](https://github.com/TheBoredTeam/boring.notch/tree/99900bf630a3d3e97fae079df2175993318d51f7):

- `boringNotch/components/Notch/NotchHomeView.swift`: artwork-led layout,
  left-aligned metadata, progress/time labels, artwork glow and paused scaling.
  Created by Hugo Persson; modified by Harsh Vardhan Goswami, Richard Kunkli,
  Mustafa Ramadan, and contributors.
- `boringNotch/ContentView.swift`: shared album-art geometry between closed
  music activity and the expanded player.

These adaptations retain GPL-3.0 attribution in source headers and
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md). Spotify controls and agent
notification policy remain Open Island's existing implementation.

## Verification

Run `swift test --filter 'MusicPresentationModelTests|SpotifyPlaybackModelTests|MediaTrackPreviewTests'`
and `zsh scripts/harness.sh lint docs build`. Synthetic harness scenarios cover
the player, compact track preview, and track changes without controlling Spotify.
Use the refreshed development bundle for real playback verification.

```sh
OPEN_ISLAND_HARNESS_SCENARIO=spotifyPlayer zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=spotifyTrackPreview zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=spotifyTrackChange zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=spotifyPaused zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=spotifyLongTitle zsh scripts/harness.sh smoke
```

The harness uses original geometric covers. Its AppKit cache-display PNGs can
omit SwiftUI blur compositing, so assess the artwork glow in the live app.
