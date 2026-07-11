pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool armed: false
    property bool flashing: false
    property string kind: "volume"
    property string focusMonitor: ""

    readonly property real brightness: BacklightService.brightness
    readonly property real volume: AudioLevelService.volume
    readonly property bool muted: AudioLevelService.muted

    readonly property real barLevel: kind === "brightness" ? brightness : volume
    readonly property int barPct: Math.round(barLevel * 100)

    readonly property real desiredW: 248
    readonly property real desiredH: 44

    function flash(which) {
        if (!armed)
            return false
        const mon = Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
        if (!mon.length)
            return false
        kind = which
        focusMonitor = mon
        flashing = true
        hideTimer.interval = 1800
        hideTimer.restart()
        return true
    }

    function visibleOnMonitor(screenName) {
        return flashing && focusMonitor === screenName
            && (kind === "volume" || kind === "brightness")
    }

    Timer {
        interval: 800
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1800
        onTriggered: root.flashing = false
    }

    Connections {
        target: AudioLevelService
        function onLevelChanged() { root.flash("volume") }
    }

    Connections {
        target: BacklightService
        function onChanged() { root.flash("brightness") }
    }
}