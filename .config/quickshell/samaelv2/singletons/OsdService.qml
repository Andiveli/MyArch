pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    property bool flashing: false
    property string kind: "volume"
    property string focusMonitor: ""

    readonly property real brightness: BacklightService.brightness
    readonly property real volume: AudioLevelService.volume
    readonly property bool muted: AudioLevelService.muted

    readonly property real barLevel: kind === "brightness" ? brightness : volume
    readonly property int barPct: Math.round(barLevel * 100)

    readonly property real desiredW: 220
    readonly property real desiredH: 44

    function monitorName() {
        if (Hyprland.focusedMonitor && Hyprland.focusedMonitor.name)
            return Hyprland.focusedMonitor.name
        if (Quickshell.screens && Quickshell.screens.length > 0)
            return Quickshell.screens[0].name
        return ""
    }

    function showOsd(which) {
        const mon = monitorName()
        kind = which
        focusMonitor = mon.length ? mon : "*"
        flashing = true
        hideTimer.restart()
        pollTimer.restart()
    }

    function pulseVolume(level) {
        if (level === "mute" || level === "Muted") {
            AudioLevelService.setFromHypr(0, true)
        } else if (level !== undefined && level !== null && String(level).length) {
            AudioLevelService.setFromHypr(level, false)
        }
        showOsd("volume")
    }

    function pulseBrightness(brightnessPct) {
        const n = parseInt(brightnessPct, 10)
        if (!isNaN(n) && n >= 0)
            BacklightService.setPercent(n)
        showOsd("brightness")
    }

    function visibleOnMonitor(screenName) {
        if (!flashing || (kind !== "volume" && kind !== "brightness"))
            return false
        if (focusMonitor === "*" || !focusMonitor.length)
            return true
        if (focusMonitor === screenName)
            return true
        if (Quickshell.screens && Quickshell.screens.length === 1)
            return true
        return false
    }

    Timer {
        id: hideTimer
        interval: 1800
        repeat: false
        onTriggered: root.flashing = false
    }

    Timer {
        id: pollTimer
        interval: 250
        repeat: true
        onTriggered: {
            if (!root.flashing)
                return
            if (root.kind === "brightness")
                BacklightService.poll()
            else
                AudioLevelService.poll()
        }
    }

    onFlashingChanged: {
        if (flashing)
            pollTimer.start()
        else
            pollTimer.stop()
    }
}