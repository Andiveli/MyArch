import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.samael

SamaelPillSurface {
    id: surface

    mTop: 0
    mLeft: 0
    mRight: 0
    mBottom: 0

    onRequestClose: GlobalStates.sessionOpen = false

    implicitWidth: 480
    implicitHeight: 240

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

    readonly property int columns: 4
    property int selectedIndex: 0

    function activateAt(i) {
        const a = actions[i]
        if (!a) return
        a.run()
        GlobalStates.sessionOpen = false
    }

    // ── Keyboard API ──

    function moveH(dir) {
        const n = actions.length
        let row = Math.floor(selectedIndex / columns)
        let col = selectedIndex % columns
        col = Math.max(0, Math.min(columns - 1, col + dir))
        let idx = row * columns + col
        if (idx >= n) idx = n - 1
        selectedIndex = idx
    }

    function moveV(dir) {
        const n = actions.length
        const maxRow = Math.ceil(n / columns) - 1
        let row = Math.floor(selectedIndex / columns)
        let col = selectedIndex % columns
        row = Math.max(0, Math.min(maxRow, row + dir))
        let idx = row * columns + col
        if (idx >= n) idx = n - 1
        selectedIndex = idx
    }

    function activate() {
        activateAt(selectedIndex)
    }

    function back() {
        return false
    }

    // ── UI ──

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: SamaelStyle.menuPanelFill
        border.width: 2
        border.color: WallustColors.borderColor

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
                text: "j/k · h/l · Enter · Esc"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 8
            }

            GridLayout {
                id: grid
                Layout.alignment: Qt.AlignHCenter
                columns: surface.columns
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: surface.actions

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        width: 108
                        height: 72
                        radius: 10
                        color: index === surface.selectedIndex
                            ? WallustColors.buttonHover
                            : Qt.rgba(0, 0, 0, 0.25)
                        border.width: index === surface.selectedIndex ? 2 : 0
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
                                surface.selectedIndex = index
                                surface.activateAt(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
