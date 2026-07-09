import QtQuick
import "../../../../pill/Singletons" as PillSingletons

/**
 * Shared morph-surface base for samael's center-dock surfaces. Each surface fills
 * the centerDock body inset by its own margins (scaled by `s`), fades in with the
 * morph as it nears full openness, and is only enabled while open. The host sets
 * `open`, `s` and `morphCloseness`; the surface sets its own `mTop`/`mLeft`/`mRight`/
 * `mBottom` insets. `active` mirrors `open` for the older `onActiveChanged` hooks.
 * `requestClose()` asks the host to dismiss the surface.
 *
 * Keyboard API (overridable no-ops):
 *   moveH(dir), moveV(dir), activate(), back() -> bool
 */
Item {
    id: surface
    focus: open && !!keyboardPanel

    property real s: 1
    property bool open: false
    property real morphCloseness: 1

    property real mTop: 0
    property real mLeft: 0
    property real mRight: 0
    property real mBottom: 0

    signal requestClose()

    /** Item with Keys.onPressed (wifi menu, perf body, media manager, …) */
    property Item keyboardPanel: null

    readonly property bool active: open

    Keys.forwardTo: keyboardPanel ? [keyboardPanel] : []

    onOpenChanged: {
        if (open && keyboardPanel)
            Qt.callLater(() => keyboardPanel.forceActiveFocus())
    }

    anchors.fill: parent
    anchors.topMargin: mTop * s
    anchors.leftMargin: mLeft * s
    anchors.rightMargin: mRight * s
    anchors.bottomMargin: mBottom * s

    enabled: open
    opacity: open ? 1 : 0
    visible: open

    Behavior on opacity {
        NumberAnimation { duration: PillSingletons.Motion.fast; easing.type: Easing.OutCubic }
    }

    // --- Keyboard API (overridable no-ops) ---

    /// Horizontal navigation: -1 = left/previous, +1 = right/next
    function moveH(dir) {}

    /// Vertical navigation: -1 = up/previous, +1 = down/next
    function moveV(dir) {}

    /// Activate/confirm focused item
    function activate() {}

    /// Go back within surface. Return true if consumed, false if surface should close.
    function back() { return false; }
}
