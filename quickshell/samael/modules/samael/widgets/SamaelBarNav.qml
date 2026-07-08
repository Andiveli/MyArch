import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs
import qs.modules.common
import qs.modules.samael

// Bar "app mode": Hypr submap routes h/l/j/k/Esc here (see keybinds.lua).
Scope {
    id: root
    readonly property int maxFocus: 7
    readonly property string hyprSubmap: "samael-bar-nav"

    function setFocus(i: int) {
        GlobalStates.samaelBarFocus = Math.max(0, Math.min(maxFocus, i))
    }

    function moveH(delta: int) {
        const item = SamaelBarNavHub.currentSurfaceItem
        if (item) {
            SamaelCenterSurface.dispatchToSurface(item, delta < 0 ? "h" : "l")
            return
        }
        setFocus(GlobalStates.samaelBarFocus + delta)
    }
    
    function activateFocus() {
        const item = SamaelBarNavHub.currentSurfaceItem
        if (item) {
            SamaelCenterSurface.surfaceActivate(item)
            return
        }
        switch (GlobalStates.samaelBarFocus) {
        case 0: SamaelBarNavHub.openAppDrawer(); break
        case 1: SamaelBarNavHub.cyclePowerProfile(); break
        case 2: SamaelBarNavHub.toggleMemDisplay(); break
        case 3: SamaelBarNavHub.toggleDiskDisplay(); break
        case 4: SamaelBarNavHub.openNotificationsMenu(); break
        case 5: SamaelBarNavHub.openClockCalendar(); break
        case 6: SamaelBarNavHub.toggleAudioDrawer(); break
        case 7: SamaelBarNavHub.openSession(); break
        }
    }
    
    function actionJ() {
        const item = SamaelBarNavHub.currentSurfaceItem
        if (item) {
            SamaelCenterSurface.surfaceMoveV(item, 1)
            return
        }
        const f = GlobalStates.samaelBarFocus
        if (f === 1)
            SamaelBarNavHub.stepPowerProfile(1)
        else if (f === 6)
            SamaelBarNavHub.adjustVolume(-1)
        else
            activateFocus()
    }
    
    function actionK() {
        const item = SamaelBarNavHub.currentSurfaceItem
        if (item) {
            SamaelCenterSurface.surfaceMoveV(item, -1)
            return
        }
        const f = GlobalStates.samaelBarFocus
        if (f === 1)
            SamaelBarNavHub.stepPowerProfile(-1)
        else if (f === 6)
            SamaelBarNavHub.adjustVolume(1)
        else if (f === 5)
            SamaelBarNavHub.collapseClock()
        else
            activateFocus()
    }

    function enterHyprSubmap() {
        Hyprland.dispatch(`hl.dsp.submap("${hyprSubmap}")`)
    }

    function leaveHyprSubmap() {
        Hyprland.dispatch(`hl.dsp.submap("reset")`)
    }

        function handleEsc() {
            const item = SamaelBarNavHub.currentSurfaceItem
            if (item) {
                const consumed = SamaelCenterSurface.dispatchToSurface(item, "esc")
                if (!consumed) {
                    // Surface's back() returned false → request close
                    item.requestClose()
                }
                return
            }
            deactivate()
        }

            function deactivate() {
                GlobalStates.samaelBarNavActive = false
                SamaelBarNavHub.collapseClock()
                leaveHyprSubmap()
            }

        Connections {
            target: GlobalStates
            function onSessionOpenChanged() {
                if (GlobalStates.sessionOpen && GlobalStates.samaelBarNavActive)
                    root.deactivate()
            }
        }

    function activate() {
        GlobalStates.samaelBarNavActive = true
        setFocus(0)
        enterHyprSubmap()
    }

    function toggle() {
        if (GlobalStates.samaelBarNavActive)
            deactivate()
        else
            activate()
    }

    IpcHandler {
        target: "samaelBarNav"
        function toggle(): void { root.toggle() }
        function focus(n: int): void {
            GlobalStates.samaelBarNavActive = true
            root.setFocus(n)
            root.enterHyprSubmap()
        }
        function h(): void { if (GlobalStates.samaelBarNavActive) root.moveH(-1) }
        function l(): void { if (GlobalStates.samaelBarNavActive) root.moveH(1) }
        function j(): void { if (GlobalStates.samaelBarNavActive) root.actionJ() }
        function k(): void { if (GlobalStates.samaelBarNavActive) root.actionK() }
        function exitNav(): void { if (GlobalStates.samaelBarNavActive) root.handleEsc() }
        function enter(): void { root.activate() }
    }
}