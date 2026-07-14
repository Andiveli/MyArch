# Calendar (samaelv2)

Middle pill surface: month grid + day agenda. UI layout follows `quickshell/pill/Calendar.qml` (grid + right editor column), themed with Wallust.

## Open

- **Hyprland:** `SUPER+SHIFT+D` — bound in `~/.config/hypr/hyprland/keybinds.lua` → `quickshell:samaelCalendarMenuToggle`
- **IPC:** `qs -c samaelv2 ipc call samaelv2 openCalendar`

Requires `qs -c samaelv2` running (same as other `samael*` globals).

## Keys

| Key | Action |
|-----|--------|
| Tab | Next month |
| Shift+Tab | Previous month |
| h / l | Previous / next day (grid) |
| j / k | Next / previous week (day grid) |
| Enter | Open **agenda list** for the focused day (when events exist) |
| j / k | In list: previous / next event |
| l / Enter | In list: open **event detail** (title, time, description) |
| h | In list: back to day grid; in detail: back to list |
| r | Refresh Google/iCal feeds |
| s | Open calendar feed settings (writes `calendar-secrets.json`) |
| Esc | Detail → list → grid → close pill |

On open, view resets to **today** in the **current real month**; use Tab to browse other months.

## Google Calendar (secrets — safe for GitHub)

**Do not put iCal URLs in `config.json`.** They are credentials.

### Option A — in the UI (recommended)

1. Open the calendar (**Super+Shift+D**).
2. Press **s** → paste one **Secret iCal** URL per line (Google Calendar → Settings → Integrate calendar).
3. **Enter** to save → fetches events automatically.
4. File written: `calendar-secrets.json` (gitignored).

### Option B — edit the secrets file by hand

```sh
cp calendar-secrets.example.json calendar-secrets.json
# edit icalUrls, then open calendar or press r
```

### Option C — environment variables

For Hyprland / launch scripts:

```bash
export SAMAELV2_CALENDAR_ICAL_URLS="https://calendar.google.com/calendar/ical/…/basic.ics"
# multiple calendars (comma-separated):
export SAMAELV2_CALENDAR_ICAL_URLS="url1,url2"
```

Optional custom secrets path:

```bash
export SAMAELV2_CALENDAR_SECRETS="$HOME/.config/quickshell/samaelv2/calendar-secrets.json"
```

Env URLs are **merged** with `calendar-secrets.json` (deduped).

### Refresh

Open the calendar (fetch on open) or press **r**. Cache: `~/.cache/samaelv2/calendar/events.json`

Test fetch:

```sh
python3 scripts/calendar-fetch-ical.py config.json
```

## Google Tasks vs calendar events

- The iCal URL is **one calendar**. Only what that feed exports shows in samaelv2.
- **Google Tasks** often **never** appear in the main calendar’s secret iCal, or only as `VTODO` (samaelv2 shows those with a ☐ prefix when the feed includes them).
- To verify sync: create a **calendar event** (with date/time) on the **same** calendar you linked, wait 1–2 minutes, press **r** in the month view.
- Tasks need a **due date** and must appear on the calendar grid in Google’s UI to have a chance in iCal.

## Morph size

`middle.surfaces.calendar` in `config.json` (default 500×300; grows with agenda column).