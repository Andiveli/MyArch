import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.samael

Item {
    id: root
    focus: true

    property var devices: []
    property int selectedIndex: 0
    property bool vimPendingG: false
    property string filterText: ""

    readonly property var filteredDevices: {
        const q = filterText.trim().toLowerCase()
        if (!q.length)
            return devices
        return devices.filter(d => (d.name || "").toLowerCase().includes(q))
    }

    function rebuildDevices() {
        devices = BluetoothStatus.friendlyDeviceList
        if (selectedIndex >= filteredDevices.length)
            selectedIndex = Math.max(0, filteredDevices.length - 1)
    }

    function moveToIndex(index) {
        const n = filteredDevices.length
        if (n === 0)
            return
        selectedIndex = Math.max(0, Math.min(index, n - 1))
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function moveSelection(delta) {
        const n = filteredDevices.length
        if (n === 0)
            return
        let next = selectedIndex + delta
        if (next < 0)
            next = n - 1
        if (next >= n)
            next = 0
        moveToIndex(next)
    }

    function deviceAt(index) {
        return filteredDevices[index]
    }

    function activateAt(index) {
        const d = deviceAt(index)
        if (!d)
            return
        if (d.connected)
            d.disconnect()
        else
            d.connect()
    }

    function closeMenu() {
        GlobalStates.samaelBluetoothMenuOpen = false
    }

    function toggleBluetooth() {
        BluetoothStatus.toggleAdapter()
    }

    onFilterTextChanged: {
        if (selectedIndex >= filteredDevices.length)
            selectedIndex = Math.max(0, filteredDevices.length - 1)
    }

    Timer {
        id: vimGChordTimer
        interval: 450
        onTriggered: {
            if (root.vimPendingG) {
                root.moveToIndex(0)
                root.vimPendingG = false
            }
        }
    }

    Connections {
        target: BluetoothStatus
        function onFriendlyDeviceListChanged() { root.rebuildDevices() }
    }

    Component.onCompleted: {
        if (Bluetooth.defaultAdapter?.enabled)
            Bluetooth.defaultAdapter.discovering = true
        rebuildDevices()
    }

    implicitWidth: 320
    implicitHeight: 400

    Rectangle {
        anchors.fill: parent
        radius: 12
        color: SamaelStyle.menuPanelFill
        border.width: 2
        border.color: WallustColors.borderColor

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Bluetooth"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize + 1
                }
                Item { Layout.fillWidth: true }
                    Text {
                        text: BluetoothStatus.rfkillBlocked ? "rfkill"
                            : (Bluetooth.defaultAdapter?.discovering ? "scanning…" : (BluetoothStatus.enabled ? "on" : "off"))
                        color: BluetoothStatus.rfkillBlocked ? WallustColors.workspaceUrgent : WallustColors.sapphire
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize - 1
                }
            }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        text: BluetoothStatus.enabled ? "󰂯" : "󰂲"
                        color: WallustColors.moduleText
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: SamaelStyle.fontPixelSize
                    }
                    Text {
                        text: BluetoothStatus.rfkillBlocked
                            ? "t unblock (rfkill) · p pair · f forget"
                            : "t toggle · p pair · f forget"
                        color: WallustColors.buttonHover
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: SamaelStyle.fontPixelSize - 2
                    }
                }

            TextField {
                id: filterField
                Layout.fillWidth: true
                placeholderText: "/ filter"
                color: WallustColors.moduleText
                font.family: SamaelStyle.fontFamily
                font.pixelSize: SamaelStyle.fontPixelSize
                padding: 6
                background: Rectangle {
                    radius: 6
                    color: Qt.rgba(0, 0, 0, 0.35)
                    border.color: WallustColors.borderColor
                }
                onTextChanged: root.filterText = text
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                model: root.filteredDevices
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: if (currentIndex >= 0)
                    root.selectedIndex = currentIndex

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: list.width
                    height: 36
                    radius: 8
                    color: index === root.selectedIndex ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.2)
                    border.width: index === root.selectedIndex ? 1 : 0
                    border.color: WallustColors.workspaceActive

                    property var dev: modelData

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6
                        Text {
                            text: dev?.connected ? "󰂱" : "󰂯"
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                            color: WallustColors.moduleText
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                Layout.fillWidth: true
                                text: dev?.name || "?"
                                elide: Text.ElideRight
                                color: WallustColors.moduleText
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: SamaelStyle.fontPixelSize
                            }
                            Text {
                                visible: dev?.paired || dev?.connected
                                text: (dev?.connected ? "connected" : "paired")
                                    + (dev?.batteryAvailable ? " · " + Math.round(dev.battery * 100) + "%" : "")
                                color: WallustColors.sapphire
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: Math.max(8, SamaelStyle.fontPixelSize - 2)
                            }
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

            Text {
                text: "j/k · Enter conn · t BT · p pair · f forget · r scan · Esc"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 8
            }
        }
    }

    Keys.onPressed: event => {
        const text = event.text
        const key = event.key
        const d = deviceAt(selectedIndex)
        if (key === Qt.Key_Escape) {
            closeMenu()
            event.accepted = true
            return
        }
        if (key === Qt.Key_Slash) {
            filterField.forceActiveFocus()
            event.accepted = true
            return
        }
        if (key === Qt.Key_Return || key === Qt.Key_Enter) {
            activateAt(selectedIndex)
            event.accepted = true
            return
        }
        if (text === "j" || key === Qt.Key_Down) {
            moveSelection(1)
            event.accepted = true
            return
        }
        if (text === "k" || key === Qt.Key_Up) {
            moveSelection(-1)
            event.accepted = true
            return
        }
        if (text === "g" && !(event.modifiers & Qt.ShiftModifier)) {
            if (vimPendingG) {
                moveToIndex(0)
                vimPendingG = false
            } else {
                vimPendingG = true
                vimGChordTimer.restart()
            }
            event.accepted = true
            return
        }
        if (text === "G" || (text === "g" && (event.modifiers & Qt.ShiftModifier))) {
            vimPendingG = false
            moveToIndex(filteredDevices.length - 1)
            event.accepted = true
            return
        }
        if (text === "r" || key === Qt.Key_R) {
            if (Bluetooth.defaultAdapter?.enabled)
                Bluetooth.defaultAdapter.discovering = true
            event.accepted = true
            return
        }
        if (text === "t" || key === Qt.Key_T) {
            toggleBluetooth()
            event.accepted = true
            return
        }
        if ((text === "p" || key === Qt.Key_P) && d) {
            if (!d.paired)
                d.pair()
            event.accepted = true
            return
        }
        if ((text === "f" || key === Qt.Key_F) && d) {
            if (d.paired)
                d.forget()
            event.accepted = true
        }
    }

    Connections {
        target: GlobalStates
        function onSamaelBluetoothMenuOpenChanged() {
            if (GlobalStates.samaelBluetoothMenuOpen) {
                BluetoothStatus.refreshRfkillState()
                rebuildDevices()
                if (Bluetooth.defaultAdapter?.enabled)
                    Bluetooth.defaultAdapter.discovering = true
                Qt.callLater(() => root.forceActiveFocus())
            }
        }
    }
}