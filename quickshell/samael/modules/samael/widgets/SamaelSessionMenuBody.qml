import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.samael

/**
 * Session action grid for center-pill morph (no fullscreen overlay).
 */
Item {
    id: root
    focus: true

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

    property int selectedIndex: 0
    property int columns: 4

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    function closeMenu() {
        GlobalStates.sessionOpen = false
    }

    function activateAt(i) {
        const a = actions[i]
        if (!a)
            return
        a.run()
        closeMenu()
    }

    function moveSel(dr, dc) {
        const n = actions.length
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
        SamaelSessionHub.panel = root
        if (GlobalStates.samaelBarNavActive)
            GlobalStates.samaelBarNavActive = false
        Qt.callLater(() => root.forceActiveFocus())
    }
    Component.onDestruction: {
        if (SamaelSessionHub.panel === root)
            SamaelSessionHub.panel = null
    }

    Rectangle {
        id: card
        radius: 14
        color: WallustColors.moduleBackground
        border.width: 2
        border.color: WallustColors.borderColor
        implicitWidth: grid.implicitWidth + 28
        implicitHeight: grid.implicitHeight + 70

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                root.closeMenu()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.activateAt(root.selectedIndex)
                event.accepted = true
                return
            }
            const t = event.text
            if (t === "j" || event.key === Qt.Key_Down) {
                root.moveSel(1, 0)
                event.accepted = true
            } else if (t === "k" || event.key === Qt.Key_Up) {
                root.moveSel(-1, 0)
                event.accepted = true
            } else if (t === "h" || event.key === Qt.Key_Left) {
                root.moveSel(0, -1)
                event.accepted = true
            } else if (t === "l" || event.key === Qt.Key_Right) {
                root.moveSel(0, 1)
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
                columns: root.columns
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
                        color: index === root.selectedIndex
                            ? WallustColors.buttonHover
                            : Qt.rgba(0, 0, 0, 0.25)
                        border.width: index === root.selectedIndex ? 2 : 0
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
                                root.selectedIndex = index
                                root.activateAt(index)
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: GlobalStates
        function onSessionOpenChanged() {
            if (!GlobalStates.sessionOpen) {
                Hyprland.dispatch(`hl.dsp.submap("reset")`)
                return
            }
            Hyprland.dispatch(`hl.dsp.submap("reset")`)
            Qt.callLater(() => Hyprland.dispatch(`hl.dsp.submap("samael-session-menu")`))
            Qt.callLater(() => root.forceActiveFocus())
        }
    }
}