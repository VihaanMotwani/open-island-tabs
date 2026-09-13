# Calendar tab

Calendar is the fourth expanded tab: Agents, Spotify, To-do, Calendar. It can
be hidden in Appearance settings. Agent alerts temporarily select Agents;
after resolution, the preferred Calendar tab returns with its selected date.

The date strip includes seven days before today and fourteen after it. Click a
date to see its agenda; Today returns to the current day. Events show their
calendar name and color, with all-day events first. Longer agendas scroll
within a fixed-height surface, keeping the notch stable while browsing dates.

## Calendar access

The first-use Connect Calendar button requests EventKit full event access on
macOS 14+. That OS permission is required to read events; the adapter exposes
no event creation, editing, deletion, or reminder APIs. It reads accounts
already configured in macOS Calendar. There is no separate Google sign-in,
network calendar connector, or persisted copy of event data.

Opening the tab only checks current authorization. Denied and write-only
access show a System Settings action; restricted access has an explanation.
Queries execute on a separate actor and return Sendable values, with identities
including the occurrence date. Selected-day intervals use Calendar arithmetic,
including daylight-saving transitions. Older query results cannot replace a
newer selection, and a permission recheck prevents publishing events after
access is revoked.

The visible tab refreshes on entry, EventKit changes, app activation, and day
changes. There is no calendar polling timer. Calendar needs the usage
description supplied by `scripts/launch-dev-app.sh` and `scripts/package-app.sh`.
A raw `swift run OpenIslandApp` executable instead explains that an app bundle
is needed when Connect is clicked, avoiding an OS privacy termination.

## Source and attribution

Adapted from [Boring Notch at 99900bf](https://github.com/TheBoredTeam/boring.notch/tree/99900bf630a3d3e97fae079df2175993318d51f7):

- `boringNotch/components/Calendar/BoringCalendar.swift`: date-strip and agenda layout.
- `boringNotch/Providers/CalendarServiceProviding.swift`: EventKit access and event mapping, itself derived from Calendr.
- `boringNotch/ContentView.swift`: distinct opening and closing spring behavior.

Credit to Harsh Vardhan Goswami, Alexander, the Boring Notch contributors, and
Calendr's authors. Boring Notch's GPLv3 license is retained by this GPLv3
project; Calendr's MIT notice is preserved in
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md). Both notices and the GPL
license are copied into packaged app resources.

## Verification

Automated behavior checks:

```sh
swift test --filter 'CalendarAgendaModelTests|IslandTabSelectionTests|AppModelSessionListTests'
zsh scripts/harness.sh lint docs build
```

Synthetic visual scenarios, which never access personal calendars:

```sh
OPEN_ISLAND_HARNESS_SCENARIO=calendarAgenda zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=calendarConnect zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=calendarEmpty zsh scripts/harness.sh smoke
OPEN_ISLAND_HARNESS_SCENARIO=calendarDenied zsh scripts/harness.sh smoke
```

For the real permission boundary, run `zsh scripts/setup-dev-signing.sh` once,
then `zsh scripts/launch-dev-app.sh --skip-setup`. Open Calendar and click
Connect Calendar. The user grants the macOS permission. Confirm the displayed
events against macOS Calendar, select another date, then hide/reopen the tab.
Synthetic harness results do not establish that real calendar access was granted.
