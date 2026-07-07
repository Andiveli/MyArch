# Apply Progress — PR 2 of 7: Slice 3 — Surface Loaders

**Change:** `samael-pill-morph`
**Batch:** PR 2 of 7 (stacked-to-main)
**Phase:** sdd-apply
**Status:** Complete ✓

---

## Structured Status Consumed

- `actionContext.mode`: implementation
- `allowedEditRoots`: `/home/samael/.config/quickshell`
- `applyState`: ready
- `artifactStore`: openspec

---

## Tasks Completed

### Slice 3: Surface Loaders — Embed All 10 Surfaces (✅ all 5)

- [x] **3.1** — Cross-fade layers inside `centerDock`
  - Wrapped existing centerModules wrapper in `idleModules` Item with cross-fade opacity
  - Added `surfaceStack` Item as sibling (z-order: surfaceStack below idleModules)
  - `idleModules.opacity` = `(effectiveSurface === "idle") ? 1 : 0`
  - `surfaceStack.opacity` = `(effectiveSurface !== "idle") ? 1 : 0`
  - Both use `Behavior on opacity { NumberAnimation { duration: Pill.Motion.standard } }`

- [x] **3.2** — 10 Loaders inside surfaceStack

  | Loader ID | Active Trigger | z |
  | ------------ | ---------------- | --- |
  | `ldPopupIsland` | `Notifications.popupList.length > 0 && !GlobalStates.screenLocked` | 0 |
  | `ldCalendar` | `GlobalStates.samaelClockDropOpen` | 1 |
  | `ldNotificationsMenu` | `GlobalStates.samaelNotificationsMenuOpen` | 2 |
  | `ldWifi` | `GlobalStates.samaelWifiMenuOpen` | 3 |
  | `ldBluetooth` | `GlobalStates.samaelBluetoothMenuOpen` | 4 |
  | `ldScreenRecorder` | `GlobalStates.samaelRecorderOpen` | 5 |
  | `ldWallpaper` | `GlobalStates.wallpaperSelectorOpen` | 6 |
  | `ldPower` | `GlobalStates.sessionOpen` | 7 |
  | `ldMedia` | `GlobalStates.mediaControlsOpen \|\| GlobalStates.samaelMediaClosing` | 8 |
  | `ldPerformance` | `GlobalStates.samaelPerformanceDropOpen \|\| GlobalStates.samaelPerformanceClosing` | 9 |

- [x] **3.3** — Placeholder content with SamaelPillSurface wrapping
  - Each Loader's sourceComponent wraps a colored Rectangle with Text label in SamaelPillSurface
  - SamaelPillSurface bound: `open: true`, `morphCloseness: centerDock.morphCloseness`
  - Each placeholder uses a distinct color per surface
  - Replaceable in Slice 4 with actual surface components

- [x] **3.4** — centerModules moved into idleModules wrapper
  - The existing `SamaelModuleGroup { id: centerModules; ... }` is nested inside `idleModules` Item
  - Idle module group still resolved by ID for `controller` idle entry
  - Fixed indentation inside SamaelModuleGroup (was at wrong level)

- [x] **3.5** — Loader scaffolding with SamaelPillSurface wrappers (no real surfaces yet)
  - All Loaders use `asynchronous: true`
  - `anchors.fill: parent` for positioning inside surfaceStack
  - Proper `sourceComponent: Component { SamaelPillSurface { ... } }` pattern

---

## Files Changed

| File | Status | Lines |
| ------ | -------- | ------- |
| `samael/modules/samael/SamaelBarContent.qml` | EDITED | +293 / -28 |
| `samael/tests/SamaelBarContentSurfaceStackTest.qml` | **NEW** | ~170 |
| `samael/tests/qmldir` | EDITED | +1 |

---

## TDD Evidence (RED → GREEN)

| Phase | Component | Test File | Tests | Result |
|-------|-----------|-----------|-------|--------|
| RED | SurfaceStack structure | `SamaelBarContentSurfaceStackTest.qml` | 11 (core structure, z-ordering, cross-fade, async, active bindings, placeholders) | Written ✓ |
| GREEN | SamaelBarContent.qml | Implementation matching test assertions | idleModules + surfaceStack + 10 Loaders with SamaelPillSurface | Implemented ✓ |

**Note on test execution:** `qmltestrunner` requires a running Quickshell/Wayland session. Tests are structurally valid QML with correct module imports. Structural verification via `grep` confirms all test-accessible properties exist (centerDockRef, idleModulesRef, surfaceStackRef, all 10 loader refs).

---

## Deviations from Design

| Design Point | Actual | Rationale |
| ------------- | -------- | ----------- |
| z-order in design: ldCalendar=1 through ldPerformance=9 | Same — ldPopupIsland at z=0 | Matches precedence (popupIsland is lowest active surface) |
| Wallpaper z=6 (below power z=7) | Wallpaper z=6, Power z=7 | Matches precedence: wallpaper > power (z=6 is below z=7 but precedence checks wallpaper first, so wallpaper wins regardless of z) |
| z-order comment: "highest z = topmost" | surfaceStack item ordering follows QML stacking | Loaders are children of surfaceStack; z determines visual stacking within surfaceStack |

---

## Risks Discovered

| Risk | Level | Status |
| ------ | ------- | -------- |
| SamaelPillSurface `anchors.fill: parent` combined with Loader `anchors.fill: parent` creates double anchoring | Low | Accepted; Loader fills surfaceStack, SamaelPillSurface fills Loader — deterministic nesting |
| `morphCloseness` binding in placeholder components references `centerDock.morphCloseness` (cross-scope QID resolution) | Low | centerDock is a sibling parent in the same QML scope — stable binding |
| SamaelPillSurface import needed in SamaelBarContent scope | Low | `import qs.modules.samael.widgets` provides `SamaelPillSurface` type (already imported) |

---

## Remaining Tasks

See `tasks.md` for remaining slices:

- Slice 4a–j: Surface migration (10 sub-slices)
- Slice 5: Keyboard routing
- Slice 6: Submap strategy
- Slice 7: Polish

---

## Workload / PR Boundary

- **PR 2:** Slice 3 ✅ (this PR)
- **Added lines:** ~465 (SamaelBarContent surface stack + test)
- **PR boundary:** Surface loaders with SamaelPillSurface-wrapped placeholders, cross-fade layers, idleModules wrapper
- **Next:** PR 3 — Slice 4 (Surface migration, sub-slices a–c)
