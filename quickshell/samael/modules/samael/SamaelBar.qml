pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.samael
import qs.modules.samael.widgets

Scope {
    id: bar

    SamaelBarNav { id: barNav }

    Variants {
        model: Quickshell.screens

        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
            required property ShellScreen modelData

                component: PanelWindow {
                    id: barRoot
                    screen: barLoader.modelData
                    exclusionMode: ExclusionMode.Ignore
                    implicitHeight: barContent.implicitHeight
                    /** Reserve only the bar row so media drop overlays windows */
                    exclusiveZone: barContent.barRowH + margins.top
                    WlrLayershell.namespace: "quickshell:samael:bar"
                    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

                anchors {
                    top: true
                    left: true
                    right: true
                }

                color: "transparent"

                margins {
                    top: 3
                    bottom: 0
                    left: 8
                    right: 8
                }

                SamaelBarContent {
                    id: barContent
                    barScreenName: barLoader.modelData?.name ?? ""
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                    }
                        height: implicitHeight
                    }


                }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    IpcHandler {
        target: "wallustColors"

        function reload(): void {
            WallustColors.reloadPaletteFromDisk()
        }
    }

    IpcHandler {
        target: "samaelWifiMenu"

        function toggle(): void {
            GlobalStates.samaelBluetoothMenuOpen = false
            GlobalStates.samaelNotificationsMenuOpen = false
            GlobalStates.samaelSystemSidebarOpen = false
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.samaelWifiMenuOpen = !GlobalStates.samaelWifiMenuOpen
        }
    }

    IpcHandler {
        target: "samaelBluetoothMenu"

        function toggle(): void {
            GlobalStates.samaelWifiMenuOpen = false
            GlobalStates.samaelNotificationsMenuOpen = false
            GlobalStates.samaelSystemSidebarOpen = false
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.samaelBluetoothMenuOpen = !GlobalStates.samaelBluetoothMenuOpen
        }
    }

    IpcHandler {
        target: "samaelNotificationsMenu"

        function toggle(): void {
            GlobalStates.samaelWifiMenuOpen = false
            GlobalStates.samaelBluetoothMenuOpen = false
            GlobalStates.samaelSystemSidebarOpen = false
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.samaelNotificationsMenuOpen = !GlobalStates.samaelNotificationsMenuOpen
        }
    }

    IpcHandler {
        target: "samaelSystemSidebar"

        function toggle(): void {
            SamaelBarNavHub.toggleSystemSidebar()
        }
    }

    IpcHandler {
        target: "samaelSuperMenu"

        function toggle(): void {
            SamaelBarNavHub.toggleSuperMenu()
        }

        function open(): void {
            SamaelBarNavHub.openSuperMenu()
        }

        function close(): void {
            SamaelBarNavHub.closeSuperMenu()
        }
    }

    GlobalShortcut {
        name: "samaelWifiMenuToggle"
        description: "Samael Wi-Fi menu"
        onPressed: {
            GlobalStates.samaelBluetoothMenuOpen = false
            GlobalStates.samaelSystemSidebarOpen = false
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.samaelWifiMenuOpen = !GlobalStates.samaelWifiMenuOpen
        }
    }

    GlobalShortcut {
        name: "samaelBluetoothMenuToggle"
        description: "Samael Bluetooth menu"
        onPressed: {
            GlobalStates.samaelWifiMenuOpen = false
            GlobalStates.samaelNotificationsMenuOpen = false
            GlobalStates.samaelSystemSidebarOpen = false
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.samaelBluetoothMenuOpen = !GlobalStates.samaelBluetoothMenuOpen
        }
    }

    GlobalShortcut {
        name: "samaelNotificationsMenuToggle"
        description: "Samael notifications menu"
        onPressed: {
            GlobalStates.samaelWifiMenuOpen = false
            GlobalStates.samaelBluetoothMenuOpen = false
            GlobalStates.samaelSystemSidebarOpen = false
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.samaelNotificationsMenuOpen = !GlobalStates.samaelNotificationsMenuOpen
        }
    }

    GlobalShortcut {
        name: "mediaControlsToggle"
        description: "Samael media manager panel (Hypr: Super+M)"
        onPressed: SamaelBarNavHub.toggleMediaManager()
    }

    GlobalShortcut {
        name: "samaelSuperMenuToggle"
        description: "Samael super menu / control center (Hypr: Super+Shift+M)"
        onPressed: SamaelBarNavHub.toggleSuperMenu()
    }

    GlobalShortcut {
        name: "samaelSystemSidebarToggle"
        description: "Samael system monitor sidebar"
        onPressed: SamaelBarNavHub.toggleSystemSidebar()
    }

    GlobalShortcut {
        name: "samaelPerformanceDropToggle"
        description: "Samael performance drop (Caelestia perf + processes/audio) (Hypr: Super+Shift+O)"
        onPressed: SamaelBarNavHub.togglePerformanceDrop()
    }

    GlobalShortcut {
        name: "samaelBarToggle"
        description: "Toggles Samael bar"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "samaelBarNavToggle"
        description: "Samael bar keyboard navigation (Super+Ctrl+B)"
        onPressed: barNav.toggle()
    }
    GlobalShortcut {
        name: "samaelBarNavKeyH"
        description: "Samael bar nav h (submap)"
        onPressed: { if (GlobalStates.samaelBarNavActive) barNav.moveH(-1) }
    }
    GlobalShortcut {
        name: "samaelBarNavKeyL"
        description: "Samael bar nav l (submap)"
        onPressed: { if (GlobalStates.samaelBarNavActive) barNav.moveH(1) }
    }
    GlobalShortcut {
        name: "samaelBarNavKeyJ"
        description: "Samael bar nav j (submap)"
        onPressed: { if (GlobalStates.samaelBarNavActive) barNav.actionJ() }
    }
    GlobalShortcut {
        name: "samaelBarNavKeyK"
        description: "Samael bar nav k (submap)"
        onPressed: { if (GlobalStates.samaelBarNavActive) barNav.actionK() }
    }
    GlobalShortcut {
        name: "samaelBarNavKeyEsc"
        description: "Samael bar nav Esc (submap)"
        onPressed: { if (GlobalStates.samaelBarNavActive) barNav.handleEsc() }
    }

    GlobalShortcut {
        name: "samaelSessionMenuKeyH"
        description: "Samael session menu h"
        onPressed: { if (GlobalStates.sessionOpen) SamaelSessionHub.moveSel(0, -1) }
    }
    GlobalShortcut {
        name: "samaelSessionMenuKeyL"
        description: "Samael session menu l"
        onPressed: { if (GlobalStates.sessionOpen) SamaelSessionHub.moveSel(0, 1) }
    }
    GlobalShortcut {
        name: "samaelSessionMenuKeyJ"
        description: "Samael session menu j"
        onPressed: { if (GlobalStates.sessionOpen) SamaelSessionHub.moveSel(1, 0) }
    }
    GlobalShortcut {
        name: "samaelSessionMenuKeyK"
        description: "Samael session menu k"
        onPressed: { if (GlobalStates.sessionOpen) SamaelSessionHub.moveSel(-1, 0) }
    }
    GlobalShortcut {
        name: "samaelSessionMenuKeyEnter"
        description: "Samael session menu Enter"
        onPressed: { if (GlobalStates.sessionOpen) SamaelSessionHub.activateSelected() }
    }
    GlobalShortcut {
        name: "samaelSessionMenuKeyEsc"
        description: "Samael session menu Esc"
        onPressed: { if (GlobalStates.sessionOpen) SamaelSessionHub.closeMenu() }
    }
}
