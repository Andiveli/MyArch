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

    property real s: 1
    property bool open: false
    property real morphCloseness: 1

    property real mTop: 0
    property real mLeft: 0
    property real mRight: 0
    property real mBottom: 0

    signal requestClose()

    readonly property bool active: open

    /**
     * Latched true once the open morph has first settled. The morphCloseness gate
     * is only there for the rest-to-surface open fade. A relayout inside an open
     * surface (a collapsible dropdown snapping its height into implicitHeight) also
     * jumps the target geometry, so closeness craters and the whole surface dims
     * for one frame until the body height Behavior catches up. After the surface
     * has settled, hold full opacity and let the body morph alone do the reveal.
     * Reset on close so the next open still fades in.
     */
    property bool settled: false
    onOpenChanged: if (!open) settled = false
    onMorphClosenessChanged: if (open && morphCloseness > 0.92) settled = true

    anchors.fill: parent
    anchors.topMargin: mTop * s
    anchors.leftMargin: mLeft * s
    anchors.rightMargin: mRight * s
    anchors.bottomMargin: mBottom * s

    enabled: open
    opacity: open ? (settled ? 1 : Math.pow(morphCloseness, 1.3)) : 0
    visible: opacity > 0.01

    Behavior on opacity {
        NumberAnimation { duration: PillSingletons.Motion.standard; easing.type: PillSingletons.Motion.easeStandard }
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
