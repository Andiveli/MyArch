# Samael Pill Morph — Implementation Tasks

> **Change:** `samael-pill-morph`
> **Based on:** proposal.md → specs/samael/spec.md → design.md
> **Total slices:** 7 (including 10 surface migration sub-slices)

---

## Review Workload Forecast

| Field | Value |
| ------- | ------- |
| Estimated changed lines | 1200–1700 |
| 400-line budget risk | High |
| Chained PRs recommended | Yes |
| Suggested split | PR 1 (Slices 1–2) → PR 2 (Slice 3) → PR 3 (Slice 4a–c) → PR 4 (Slice 4d–f) → PR 5 (Slice 4g–j) → PR 6 (Slices 5–6) → PR 7 (Slice 7) |
| Delivery strategy | ask-on-risk |
| Chain strategy | pending (user decision needed) |

```text
Decision needed before apply: Yes
Chained PRs recommended: Yes
Chain strategy: pending
400-line budget risk: High
```

---

## Dependencies

```
Slice 1 (Foundation) ──► Slice 2 (Controller) ──► Slice 3 (Loaders) ──► Slice 4 (Migration)
                                                                              │
                                    Slice 6 (Submap) ◄── Slice 5 (Keyboard) ◄─┘
                                                                              │
                                    Slice 7 (Polish) ◄───────────────────────┘
```

- **Slice 1** must complete before Slice 2 (base type needed by surfaces)
- **Slice 2** must complete before Slice 3 (controller needed by centerDock)
- **Slice 3** must complete before Slice 4 (Loaders needed to host migrated surfaces)
- **Slice 4** sub-slices can run in parallel but order by risk (simpler first)
- **Slices 5–6** must complete after Slice 4 (surfaces need keyboard API)
- **Slice 7** must be last (polish after everything works)

---

## Slice 1: Foundation — SamaelPillSurface + qmldir

**Difficulty:** Low
**Files touched:** 2 (1 NEW, 1 edit)
**Dependency blocker for:** All subsequent slices

- [x] **1.1** Create `samael/modules/samael/widgets/SamaelPillSurface.qml` as a standalone copy patterned after `pill/PillSurface.qml`
  - Properties: `s: real`, `open: bool`, `morphCloseness: real`, `mTop/mLeft/mRight/mBottom: real`, `settled: bool`, `active: bool`
  - Signals: `requestClose()`
  - Keyboard API (no-op overridables): `moveH(dir)`, `moveV(dir)`, `activate()`, `back() → bool`
  - Behavior: opacity gated by `open ? (settled ? 1 : pow(morphCloseness, 1.3)) : 0`
  - `settled` latch: `false` on open→false, flips to `true` when `open && morphCloseness > 0.92`
  - `Behavior on opacity { NumberAnimation { duration: Motion.standard } }`
  - Anchors margins scaled by `s`, `enabled: open`, `visible: opacity > 0.01`
  - Import `Motion.qml` from `pill/Singletons/` — verify relative path resolves

- [x] **1.2** Register `SamaelPillSurface 1.0 widgets/SamaelPillSurface.qml` in `samael/modules/samael/qmldir`

- [x] **1.3** Verify `SamaelPillSurface` can be imported and instantiated: add a minimal test import in any existing bar QML file (remove before PR merge)

**Verification:** `SamaelPillSurface {}` instantiable with no import errors. Surface gates opacity correctly when toggling `open`.

---

## Slice 2: Controller Refactor — SamaelCenterSurface + Morph Constants

**Difficulty:** Medium
**Files touched:** 2 (2 edits)
**Dependency:** Slice 1 (uses Motion import pattern verified)
**Dependency blocker for:** Slices 3–7

- [x] **2.1** Add new GlobalStates properties to `samael/GlobalStates.qml`
  - `samaelRecorderOpen: bool` (default `false`)
  - No need for `samaelSurfaceVimActive` — use `effectiveSurface !== "idle"` instead (per design decision)

- [x] **2.2** Refactor `samael/modules/samael/SamaelCenterSurface.qml`
  - Remove `samaelCenterMixerOpen` check (mixer excluded per scope)
  - Add `surfaces` lookup table (keyed by surface ID → `{ size: () => Qt.Size(w, h) }` thunk)
  - Add `targetSize: property size` computed from `surfaces[effectiveSurface].size()`
  - Add `targetW` / `targetH` convenience properties
  - Add `morphCloseness` computation based on distance from current width/height to target
  - **Add new surface IDs to precedence** (in order): `wifi`, `bluetooth`, `calendar`, `screenRecorder`
  - Updated precedence order: wallpaper → power → notificationsMenu → media → performance → wifi → bluetooth → calendar → screenRecorder → notificationPopup → idle
  - Add `dispatchToSurface(surfaceId, key)` function
  - Add convenience wrappers: `surfaceMoveH(delta)`, `surfaceMoveV(delta)`, `surfaceActivate()`, `surfaceBackOrClose()`

- [x] **2.3** Update `samael/modules/samael/SamaelBarContent.qml` — adopt Motion.* and computed geometry
  - Add import for `Motion.qml` from `pill/Singletons/`
  - Replace `Appearance.animation.samaelMediaAttach` in `Behavior on width` with `Motion.morph`, `Motion.easeMorph`, `Motion.morphCurve`
  - Replace `Behavior on height` with same Motion constants (currently no Behavior on height — add one)
  - Replace `width` conditional bindings (`GlobalStates.mediaControlsOpen ? root.mediaPanelWidth : ...`) with `centerSurfaceController.targetW`
  - Bind `height` to `centerSurfaceController.targetH`
  - Add `morphCloseness` property on centerDock linking to controller
  - Consolidate `dockExpanded` to `centerSurfaceController.effectiveSurface !== "idle"`
  - Remove `mediaPanelWidth` and `performancePanelWidth` constants (no longer used)

**Verification:** `centerDock.width`/`height` use `Motion.morph` duration and `Motion.morphCurve`. No per-surface conditionals in width/height bindings. `dockExpanded` is a single expression.

---

## Slice 3: Surface Loaders — Embed All 10 Surfaces

**Difficulty:** Medium
**Files touched:** 1 (major edit)
**Dependency:** Slice 2
**Dependency blocker for:** Slice 4

- [x] **3.1** Inside `centerDock` in `SamaelBarContent.qml`, add `surfaceStack` Item (fill parent, visible when `dockExpanded`)
  - Add `idleModules` wrapper Item for the cross-fade layer
  - Cross-fade: `idleModules.opacity = (effectiveSurface === "idle") ? 1 : 0`
  - `surfaceStack.opacity = (effectiveSurface !== "idle") ? 1 : 0`
  - Both use `Behavior on opacity { NumberAnimation { duration: Motion.standard } }`

- [x] **3.2** Add 10 Loaders inside `surfaceStack` with the following IDs and active bindings:

  | Loader ID | Active Trigger | z |
  | ----------- | ---------------- | --- |
  | `ldCalendar` | `GlobalStates.samaelClockDropOpen` | 1 |
  | `ldNotificationsMenu` | `GlobalStates.samaelNotificationsMenuOpen` | 2 |
  | `ldWifi` | `GlobalStates.samaelWifiMenuOpen` | 3 |
  | `ldBluetooth` | `GlobalStates.samaelBluetoothMenuOpen` | 4 |
  | `ldScreenRecorder` | `GlobalStates.samaelRecorderOpen` | 5 |
  | `ldWallpaper` | `GlobalStates.wallpaperSelectorOpen` | 6 |
  | `ldPower` | `GlobalStates.sessionOpen` | 7 |
  | `ldMedia` | `GlobalStates.mediaControlsOpen \|\| GlobalStates.samaelMediaClosing` | 8 |
  | `ldPerformance` | `GlobalStates.samaelPerformanceDropOpen \|\| GlobalStates.samaelPerformanceClosing` | 9 |
  | `ldPopupIsland` | `Notifications.popupList.length > 0 && !screenLocked` | 0 |

- [x] **3.3** Each Loader: `asynchronous: true` (all surfaces), `sourceComponent: null` initially
  - Wire `requestClose` from each loaded item to its respective close handler

- [x] **3.4** Move `centerModules` group from direct `centerDock` child into `idleModules` wrapper

- [x] **3.5** Remove old PanelWindow-style imports from all Loader sourceComponents (done in Slice 4) — for Slice 3, just add the Loader scaffolding with dummy content (colored rectangles) to verify z-ordering and morph

**Verification:** All 10 Loaders appear in surfaceStack. Opening any surface flag morphs centerDock to the correct size (even with placeholder content). z-ordering matches precedence. Cross-fade between idleModules and surfaceStack works.

---

## Slice 4: Surface Migration — PanelWindow to Embedded (10 sub-slices)

**Difficulty:** High (overall), Medium (per sub-slice)
**Files touched:** ~15–20
**Dependency:** Slice 3
**Dependency blocker for:** Slices 5–7

### Sub-slice 4a: Calendar

**Difficulty:** Medium

- [ ] **4a.1** Refactor `SamaelClockCalendarDrop.qml`: extract calendar content from PanelWindow shell into a `SamaelPillSurface`-based component
  - Remove `PanelWindow`, `WlrLayershell`, `screen`, `anchors` top-level wrapping
  - Wrap existing day grid content in `SamaelPillSurface { id: calendarSurface }`
  - Wire `requestClose()` to set `GlobalStates.samaelClockDropOpen = false`
  - Implement `moveH(dir)` for day grid (prev/next day within row)
  - Implement `moveV(dir)` for day grid (move up/down one week)
  - Implement `activate()` for event toggle
  - Implement `back()`: return `false` (let caller close surface)
  - Keep `SamaelClockCalendarDrop.qml` as a wrapper that provides the surface component for `ldCalendar`

- [ ] **4a.2** Update `ldCalendar` sourceComponent to point to refactored calendar

**Verification:** Calendar opens in centerDock. h/l navigates days. j/k navigates weeks. Enter toggles event view. Esc closes surface.

### Sub-slice 4b: Notifications Menu

**Difficulty:** Low (already has keyboard nav)

- [ ] **4b.1** Wrap `SamaelNotificationsMenu.qml` content in `SamaelPillSurface` base
  - Already an `Item` with `focus: true`; no PanelWindow to remove
  - Add `SamaelPillSurface` as root wrapper, move current root content inside
  - Wire `requestClose()` to set `GlobalStates.samaelNotificationsMenuOpen = false`
  - Keyboard API already exists (j/k/l/Enter/Esc/d/D/t/gg/G) — map through `moveH/moveV/activate/back`
  - Verify `back()` returns `false` (surface closes on Esc)

**Verification:** Notifications menu opens in centerDock. j/k navigates list. Enter invokes action. Esc closes.

### Sub-slice 4c: Wi-Fi

**Difficulty:** Medium

- [ ] **4c.1** Extract Wi-Fi content from `SamaelConnectionMenus.qml` into standalone surface
  - Create `samael/modules/samael/widgets/SamaelWifiSurface.qml` (new)
  - Copy wifi panel content (network list, connection logic) from `SamaelConnectionMenus.qml`
  - Wrap in `SamaelPillSurface` base
  - Wire `requestClose()` to set `GlobalStates.samaelWifiMenuOpen = false`
  - Implement `moveH(dir)` for sub-views (known networks, details)
  - Implement `moveV(dir)` for network list scrolling
  - Implement `activate()` for connect/disconnect
  - Implement `back()`: return `true` if in sub-view (go back to main), `false` if in main (close)

- [ ] **4c.2** Register `SamaelWifiSurface` in `qmldir`
- [ ] **4c.3** Update `ldWifi` sourceComponent

**Verification:** Wi-Fi surface opens in centerDock. j/k scrolls networks. Enter connects. h/l switches views. Esc closes.

### Sub-slice 4d: Bluetooth

**Difficulty:** Medium (follows wifi pattern)

- [ ] **4d.1** Extract Bluetooth content from `SamaelConnectionMenus.qml` into standalone surface
  - Create `samael/modules/samael/widgets/SamaelBluetoothSurface.qml` (new)
  - Same pattern as wifi: copy bluetooth panel content
  - Wrap in `SamaelPillSurface` base
  - Wire `requestClose()` to set `GlobalStates.samaelBluetoothMenuOpen = false`
  - Implement `moveH/moveV/activate/back` for device list + sub-views

- [ ] **4d.2** Register `SamaelBluetoothSurface` in `qmldir`
- [ ] **4d.3** Update `ldBluetooth` sourceComponent

**Verification:** Bluetooth surface opens in centerDock. j/k scrolls devices. Enter connects/pairs. h/l switches views. Esc closes.

### Sub-slice 4e: Screen Recording

**Difficulty:** Medium (NEW surface)

- [ ] **4e.1** Create `samael/modules/samael/widgets/SamaelScreenRecorderSurface.qml` (new)
  - Wrap in `SamaelPillSurface` base
  - Mode selector (fullscreen, region, window) navigable with h/l
  - Start/stop button via Enter
  - Implement `moveH(dir)` for mode selection
  - Implement `activate()` for toggle recording
  - Wire `requestClose()` to set `GlobalStates.samaelRecorderOpen = false`

- [ ] **4e.2** Register `SamaelScreenRecorderSurface` in `qmldir`
- [ ] **4e.3** Update `ldScreenRecorder` sourceComponent

**Verification:** Screen recording surface opens. h/l changes mode. Enter starts/stops. Esc closes.

### Sub-slice 4f: Wallpaper Picker

**Difficulty:** Low (already has keyboard nav)

- [ ] **4f.1** Wrap `SamaelWallpaperPickerContent.qml` in `SamaelPillSurface` base
  - Already an `Item` with full keyboard nav (hjkl/Enter/Esc/gg/G/r)
  - Add `SamaelPillSurface` wrapper
  - Wire `requestClose()` to set `GlobalStates.wallpaperSelectorOpen = false`
  - Map existing keyboard nav through `moveH/moveV/activate/back`

- [ ] **4f.2** Update `ldWallpaper` sourceComponent (currently `SamaelWallpaperPicker.qml` wraps as PanelWindow — remove that wrapper, point Loader directly to content)
  - Refactor `SamaelWallpaperPicker.qml` to provide the surface component (or inline it)

**Verification:** Wallpaper picker opens in centerDock. h/l navigates thumbs. j/k moves rows. Enter applies. r random. `/` search. Esc closes.

### Sub-slice 4g: Power / Session

**Difficulty:** Low (already has keyboard nav)

- [ ] **4g.1** Wrap `SamaelSessionMenuBody.qml` in `SamaelPillSurface` base
  - Already an `Item` with hjkl/Enter/Esc grid nav
  - Add `SamaelPillSurface` wrapper
  - Wire `requestClose()` to set `GlobalStates.sessionOpen = false`
  - Map existing keyboard nav through `moveH/moveV/activate/back`

- [ ] **4g.2** Update `ldPower` sourceComponent
  - Remove old `SamaelSessionMenu.qml` PanelWindow wrapper pattern

**Verification:** Power surface opens in centerDock. hjkl navigates grid. Enter fires action. Esc closes.

### Sub-slice 4h: Media Controls

**Difficulty:** Medium

- [ ] **4h.1** Extract media controls content from `SamaelMediaManagerDrop.qml` PanelWindow
  - Create `samael/modules/samael/widgets/SamaelMediaSurface.qml` (new)
  - Remove `PanelWindow`, `WlrLayershell`, `screen` wrapper
  - Wrap media controls (prev/play-pause/next, seek bar, shuffle/loop) in `SamaelPillSurface`
  - Wire `requestClose()` to set `GlobalStates.mediaControlsOpen = false`
  - Implement `moveH(dir)` for prev/play/next focus ring
  - Implement `moveV(dir)` for seek (j=-10s, k=+10s)
  - Implement `activate()` for focused control
  - Handle close animation: `GlobalStates.samaelMediaClosing` flag sequence

- [ ] **4h.2** Register `SamaelMediaSurface` in `qmldir`
- [ ] **4h.3** Update `ldMedia` sourceComponent

**Verification:** Media surface opens in centerDock. h/l moves across prev/play/next. j/k seeks. Enter activates. Esc closes with animation.

### Sub-slice 4i: Performance / Sysmon

**Difficulty:** Low (already has keyboard nav)

- [ ] **4i.1** Wrap `SamaelPerformanceDropBody.qml` in `SamaelPillSurface` base
  - Already an `Item` with tab nav and keyboard support
  - Add `SamaelPillSurface` wrapper
  - Wire `requestClose()` to set `GlobalStates.samaelPerformanceDropOpen = false`
  - Implement `moveH(dir)` for tab switching (h/l)
  - Implement `moveV(dir)` for process list scrolling
  - Implement `activate()` for focused action

- [ ] **4i.2** Update `ldPerformance` sourceComponent
  - Remove old `SamaelPerformanceDrop.qml` PanelWindow wrapper pattern

**Verification:** Performance surface opens in centerDock. h/l switches tabs. j/k navigates processes. Enter toggles action. Esc closes with animation.

### Sub-slice 4j: Notification Popup Island

**Difficulty:** Low

- [ ] **4j.1** Create `samael/modules/samael/widgets/SamaelPopupIslandSurface.qml` (new)
  - Extract popup listview content from `SamaelNotificationIsland.qml` PanelWindow
  - Wrap in `SamaelPillSurface` base
  - Wire `requestClose()` — popups dismiss individually
  - Minimal keyboard: Esc dismisses current popup

- [ ] **4j.2** Register `SamaelPopupIslandSurface` in `qmldir`
- [ ] **4j.3** Update `ldPopupIsland` sourceComponent

**Verification:** Notification popup island appears in centerDock. Esc dismisses.

---

## Slice 5: Keyboard Routing

**Difficulty:** Medium
**Files touched:** 3 (3 edits)
**Dependency:** Slices 1–4 (all surfaces must implement keyboard API)

- [ ] **5.1** Update `samael/modules/samael/widgets/SamaelBarNav.qml` to check `effectiveSurface` in handlers
  - `moveH(delta)`: route to `centerSurfaceController.surfaceMoveH` when surface open, `setFocus` when idle
  - `moveV(delta)`: route to `centerSurfaceController.surfaceMoveV` when surface open (j/k), same as existing actionJ/actionK when idle
  - `activateFocus()`: route to `centerSurfaceController.surfaceActivate()` when surface open
  - `Esc`: route to `centerSurfaceController.surfaceBackOrClose()` when surface open, `deactivate()` when idle
  - `actionJ()` / `actionK()`: defer to surface nav when surface open

- [ ] **5.2** Update `samael/modules/samael/SamaelBarNavHub.qml`
  - Add `surfaceMoveH(delta)`, `surfaceMoveV(delta)`, `surfaceActivate()`, `surfaceBack()` dispatch functions
  - These delegates to `SamaelCenterSurface.surfaceMoveH` etc. (or route directly through the controller singleton)

- [ ] **5.3** Update `samael/modules/samael/SamaelBar.qml` GlobalShortcut handlers
  - `samaelBarNavKeyH/L/J/K` handlers: add surface-open check before routing to barNav
  - When `effectiveSurface !== "idle"` → route through `centerSurfaceController.surfaceMoveH/L/V/Activate/Back`
  - When `effectiveSurface === "idle"` → route to barNav (existing behavior)
  - `samaelBarNavKeyEsc`: call `centerSurfaceController.surfaceBackOrClose()` if surface open, `barNav.deactivate()` if not
  - No new shortcut registrations needed

**Verification:** `super+ctrl+b` activates bar nav. h/l moves bar focus when idle. j opens surface with keyboard focus. Inside surface: h/l/j/k/Enter/Esc navigate surface content. Esc closes surface and returns to bar nav. Double Esc deactivates bar nav.

---

## Slice 6: Submap Strategy (Simplified — Single Submap)

**Difficulty:** Low
**Files touched:** 1 (1 edit)
**Dependency:** Slice 5
**Note:** Per design section 6.4, uses single `samael-bar-nav` submap with dynamic routing. No per-surface submap registration needed.

- [ ] **6.1** Verify existing `samael-bar-nav` submap registration in `keybinds.lua` (or equivalent) is sufficient
  - Confirm keys h/l/j/k/Enter/Esc are bound to GlobalShortcut targets

- [ ] **6.2** Ensure `SamaelBar.qml` `samaelBarNavToggle` handler correctly enters `samael-bar-nav` submap on activate

- [ ] **6.3** Remove old `SamaelSessionMenuKey*` GlobalShortcuts from `SamaelBar.qml` (h/l/j/k/Enter/Esc for session) — no longer needed, session navigates via the merged surface keyboard routing

- [ ] **6.4** Verify `leaveHyprSubmap` on deactivate resets to `"reset"` — no stray submap state

**Verification:** Single `samael-bar-nav` submap handles both bar and surface navigation. No additional submaps registered. Esc always returns to clean state.

---

## Slice 7: Polish — Edge Cases, Close Animations, Visual Validation

**Difficulty:** Medium
**Files touched:** 3–5
**Dependency:** Slices 1–6

- [ ] **7.1** Morph closeness gate verification
  - Confirm surface opacity is < 0.3 when `morphCloseness < 0.5`
  - Confirm surface opacity reaches 1.0 at end of morph
  - Verify `settled` latch prevents flicker on internal relayout

- [ ] **7.2** Close animation handling for media and performance
  - Verify `samaelMediaClosing` flag keeps `ldMedia` active during close morph (420ms)
  - Verify `samaelPerformanceClosing` flag keeps `ldPerformance` active during close morph
  - Add `Timer` or connect `Behavior on width` completion to clear close flags after animation finishes

- [ ] **7.3** Esc reliability testing
  - Surface open → Esc → surface closes, bar nav still active
  - Esc again → bar nav deactivates
  - Rapid Esc (10x) — no trapped state, no crash

- [ ] **7.4** Multi-monitor verification
  - Surface opens on all monitors' centerDocks simultaneously
  - No duplicate anchor publishing issues
  - Keyboard nav only affects focused monitor (GlobalShortcut behavior)

- [ ] **7.5** Verify `SamaelBarNavHub.closeSamaelOverlaysExcept` references all new surface IDs
  - Add `clock`, `recorder` to the close-except mapping
  - Ensure wifi/bt/calendar/recorder close flags when other surfaces open

- [ ] **7.6** Remove dead code
  - Remove `mediaPanelWidth` / `performancePanelWidth` constants (if moved to surfaces table)
  - Remove any remaining `Appearance.animation.samaelMediaAttach` references
  - Remove unused PanelWindow wrappers after migration

- [ ] **7.7** Visual regression check
  - Dock chrome (border + fill) follows centerDock bounds correctly
  - Surface content aligns within margins
  - Cross-fade between idle modules and surfaces is smooth
  - Focus highlight renders within each surface delegate

---

## Verify Tasks

Run these after all slices are implemented:

- [ ] **V.1** `AC-1`: Inspect `Behavior on width` — duration is `Motion.morph`, easing is `Motion.easeMorph`, bezierCurve is `Motion.morphCurve`
- [ ] **V.2** `AC-2`: Grep `SamaelBarContent.qml` for `GlobalStates.mediaControlsOpen` in width/height bindings — must be absent
- [ ] **V.3** `AC-3`: Visual: morphCloseness gate test — surface opacity < 0.3 at 50% morph
- [ ] **V.4** `AC-4`: `super+ctrl+b` activates bar nav, enters `samael-bar-nav` submap
- [ ] **V.5** `AC-5`: h/l moves bar focus when idle, no surface open
- [ ] **V.6** `AC-6`: j on clock focus opens calendar, h/l navigates days
- [ ] **V.7** `AC-7`: Esc closes surface, bar nav stays active
- [ ] **V.8** `AC-8`: Double Esc deactivates bar nav
- [ ] **V.9** `AC-9`: Per-surface keyboard spec verified for all 9 surfaces + popupIsland
- [ ] **V.10** `AC-10`: (N/A — single submap strategy, no per-surface submaps) — skip, replaced by dynamic routing
- [ ] **V.11** `AC-11`: Precedence verified: wallpaper > power > notificationsMenu > media > performance > wifi > bluetooth > calendar > screenRecorder > popupIsland > idle
- [ ] **V.12** `AC-12`: No dead keys — Esc always works, 10 rapid presses test
- [ ] **V.13** `AC-13`: All 9 surfaces open/close from bar module clicks
- [ ] **V.14** `AC-14`: Media/performance mutual exclusion — opening one closes the other
- [ ] **V.15** `AC-15`: Media close animation (`samaelMediaClosing`) preserves morphCloseness pattern
- [ ] **V.16** `AC-16`: Screen recording surface opens and responds to keyboard (h/l modes, Enter start/stop)
- [ ] **V.17** Surface keyboard does NOT leak to bar focus: with surface open, pressing h does NOT move bar focus
- [ ] **V.18** Popup island does NOT steal focus when notifications menu is open (precedence: menu > popup)
- [ ] **V.19** Multi-monitor: surface morphs on both monitors when triggered
- [ ] **V.20** `centerDock.height` animates to surface's `implicitHeight` with `Motion.morph` curve
