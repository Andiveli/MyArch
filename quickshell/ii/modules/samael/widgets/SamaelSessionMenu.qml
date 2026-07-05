import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.samael

Scope {
    id: root

    readonly property var actions: [
        { id: "lock", label: "Lock", icon: "󰌾", run: () => Session.lock() },
        { id: "sleep", label: "Sleep", icon: "󰤄", run: () => Session.suspend() },
        { id: "logout", label: "Logout", icon: "󰍃", run: () => Session.logout() },
        { id: "taskmgr", label: "Task Manager", icon: "󰨇", run: () => Session.launchTaskManager() },
        { id: "hibernate", label: "Hibernate", icon: "󰤁", run: () => Session.hibernate() },
        { id: "shutdown", label: "Shutdown", icon: "󰐥", run: () => Session.poweroff() },
        { id: "reboot", label: "Reboot", icon: "󰜉", run: () => Session.reboot() },
        { id: "firmware", label: "UEFI / Firmware", icon: "󰒓", run: () => Session.rebootToFirmware() },
    ]

    readonly property string hyprSubmap: "samael-session-menu"

    function enterHyprSubmap() {
        Hyprland.dispatch(`hl.dsp.submap("${hyprSubmap}")`)
    }

    function leaveHyprSubmap() {
        Hyprland.dispatch(`hl.dsp.submap("reset")`)
    }

    Loader {
        active: GlobalStates.sessionOpen && !GlobalStates.screenLocked
        onActiveChanged: {
            if (!active) {
                SamaelSessionHub.panel = null
                root.leaveHyprSubmap()
            }
        }

        sourceComponent: PanelWindow {
            id: win
            screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name)
                ?? Quickshell.screens[0]

            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.namespace: "quickshell:samael:sessionMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            color: Qt.rgba(0, 0, 0, 0.45)

            anchors {
                top: true
                left: true
                right: true
            }
            implicitWidth: screen?.width ?? 1920
            implicitHeight: screen?.height ?? 1080

            property int selectedIndex: 0
            property int columns: 4

            function closeMenu() {
                GlobalStates.sessionOpen = false
                root.leaveHyprSubmap()
            }

            function activateAt(i) {
                const a = root.actions[i]
                if (!a)
                    return
                a.run()
                closeMenu()
            }

            function moveSel(dr, dc) {
                const n = root.actions.length
                if (n === 0)
                    return
                let row = Math.floor(selectedIndex / columns)
                let col = selectedIndex % columns
                const maxRow = Math.ceil(n / columns) - 1
                row = Math.max(0, Math.min(maxRow, row + dr))
                col = Math.max(0, Math.min(columns - 1, col + dc))
                let idx = row * columns + col
                if (idx >= n)
                    idx = n - 1
                selectedIndex = idx
            }

            Component.onCompleted: {
                SamaelSessionHub.panel = win
                GlobalFocusGrab.addDismissable(win)
                if (GlobalStates.samaelBarNavActive)
                    GlobalStates.samaelBarNavActive = false
                Hyprland.dispatch(`hl.dsp.submap("reset")`)
                Qt.callLater(() => {
                    root.enterHyprSubmap()
                    sessionCard.forceActiveFocus()
                })
            }
            Component.onDestruction: {
                GlobalFocusGrab.removeDismissable(win)
                if (SamaelSessionHub.panel === win)
                    SamaelSessionHub.panel = null
            }
            Connections {
                target: GlobalFocusGrab
                function onDismissed() { win.closeMenu() }
            }

            MouseArea {
                anchors.fill: parent
                z: 0
                onClicked: win.closeMenu()
            }

            Rectangle {
                id: sessionCard
                anchors.centerIn: parent
                width: grid.implicitWidth + 28
                height: grid.implicitHeight + 70
                radius: 14
                color: WallustColors.moduleBackground
                border.width: 2
                border.color: WallustColors.borderColor
                z: 1
                focus: true
                activeFocusOnTab: true

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        win.closeMenu()
                        event.accepted = true
                        return
                    }
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        win.activateAt(win.selectedIndex)
                        event.accepted = true
                        return
                    }
                    const t = event.text
                    if (t === "j" || event.key === Qt.Key_Down) {
                        win.moveSel(1, 0)
                        event.accepted = true
                    } else if (t === "k" || event.key === Qt.Key_Up) {
                        win.moveSel(-1, 0)
                        event.accepted = true
                    } else if (t === "h" || event.key === Qt.Key_Left) {
                        win.moveSel(0, -1)
                        event.accepted = true
                    } else if (t === "l" || event.key === Qt.Key_Right) {
                        win.moveSel(0, 1)
                        event.accepted = true
                    }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "Session"
                        color: WallustColors.moduleText
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: SamaelStyle.fontPixelSize + 2
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: "j/k ↑↓ · h/l ←→ · Enter · Esc"
                        color: WallustColors.buttonHover
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 8
                    }

                    GridLayout {
                        id: grid
                        Layout.alignment: Qt.AlignHCenter
                        columns: win.columns
                        columnSpacing: 10
                        rowSpacing: 10

                        Repeater {
                            model: root.actions
                            delegate: Rectangle {
                                required property int index
                                required property var modelData
                                width: 108
                                height: 72
                                radius: 10
                                color: index === win.selectedIndex
                                    ? WallustColors.buttonHover
                                    : Qt.rgba(0, 0, 0, 0.25)
                                border.width: index === win.selectedIndex ? 2 : 0
                                border.color: WallustColors.workspaceActive

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.icon
                                        font.pixelSize: 22
                                        color: WallustColors.moduleText
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: modelData.label
                                        font.family: SamaelStyle.fontFamily
                                        font.pixelSize: SamaelStyle.fontPixelSize - 1
                                        color: WallustColors.sapphire
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        win.selectedIndex = index
                                        win.activateAt(index)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}