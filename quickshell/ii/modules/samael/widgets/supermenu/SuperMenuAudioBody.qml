import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.modules.samael

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 380

    property int sectionIndex: 0 // 0 default out, 1 default in, 2.. streams
    property bool devicePickerOpen: false
    property string devicePickerMode: "out"
    property int devicePickerIndex: 0
    property bool routePickerOpen: false
    property int routeStreamIndex: 0
    property int routeSinkIndex: 0

    readonly property int streamCount: Math.min(3, Audio.outputAppNodes.length)
    readonly property int sectionCount: 2 + streamCount

    function mprisForStream(node) {
        if (!node)
            return null
        const app = (Audio.appNodeDisplayName(node) || "").toLowerCase()
        const players = MprisController.players
        for (let i = 0; i < players.length; i++) {
            const p = players[i]
            const dbus = (p.dbusName || "").toLowerCase()
            if (app.includes("spotify") && dbus.includes("spotify"))
                return p
            if ((app.includes("firefox") || app.includes("zen")) && dbus.includes("firefox"))
                return p
        }
        if (players.length === 1)
            return players[0]
        return null
    }

    function streamVolume(node) {
        const m = mprisForStream(node)
        if (m && m.volumeSupported && m.canControl)
            return m.volume
        return node?.audio?.volume ?? 0
    }

    function setStreamVolume(node, value) {
        const v = Math.max(0, Math.min(1, value))
        const m = mprisForStream(node)
        if (m && m.volumeSupported && m.canControl)
            m.volume = v
        if (node?.audio)
            node.audio.volume = v
    }

    function pickerList() {
        return devicePickerMode === "in" ? Audio.inputDevices : Audio.outputDevices
    }

    function openDevicePicker(mode) {
        const list = mode === "in" ? Audio.inputDevices : Audio.outputDevices
        if (!list.length)
            return
        devicePickerMode = mode
        const current = mode === "in" ? Audio.source : Audio.sink
        let idx = 0
        for (let i = 0; i < list.length; i++) {
            if (list[i] === current) {
                idx = i
                break
            }
        }
        devicePickerIndex = idx
        devicePickerOpen = true
        routePickerOpen = false
    }

    function confirmDevicePicker() {
        const list = pickerList()
        if (devicePickerIndex < 0 || devicePickerIndex >= list.length)
            return
        const node = list[devicePickerIndex]
        if (devicePickerMode === "in")
            Audio.setDefaultSource(node)
        else
            Audio.setDefaultSink(node)
        devicePickerOpen = false
    }

    function openRoutePicker(streamIdx) {
        if (!Audio.outputDevices.length)
            return
        routeStreamIndex = streamIdx
        routeSinkIndex = 0
        routePickerOpen = true
        devicePickerOpen = false
    }

    function confirmRoute() {
        const node = Audio.outputAppNodes[routeStreamIndex]
        const sink = Audio.outputDevices[routeSinkIndex]
        if (node && sink)
            Audio.moveOutputStreamToSink(node, sink)
        routePickerOpen = false
    }

    function handleKey(event): bool {
        if (devicePickerOpen) {
            const list = pickerList()
            const n = list.length
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                devicePickerIndex = (devicePickerIndex + 1) % n
                event.accepted = true
                return true
            }
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                devicePickerIndex = (devicePickerIndex - 1 + n) % n
                event.accepted = true
                return true
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                confirmDevicePicker()
                event.accepted = true
                return true
            }
            if (event.key === Qt.Key_Escape) {
                devicePickerOpen = false
                event.accepted = true
                return true
            }
            return false
        }
        if (routePickerOpen) {
            const n = Audio.outputDevices.length
            if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
                routeSinkIndex = (routeSinkIndex + 1) % n
                event.accepted = true
                return true
            }
            if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
                routeSinkIndex = (routeSinkIndex - 1 + n) % n
                event.accepted = true
                return true
            }
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                confirmRoute()
                event.accepted = true
                return true
            }
            if (event.key === Qt.Key_Escape) {
                routePickerOpen = false
                event.accepted = true
                return true
            }
            return false
        }

        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            sectionIndex = Math.min(sectionCount - 1, sectionIndex + 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            sectionIndex = Math.max(0, sectionIndex - 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (sectionIndex === 0)
                openDevicePicker("out")
            else if (sectionIndex === 1)
                openDevicePicker("in")
            else
                openRoutePicker(sectionIndex - 2)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
            if (sectionIndex >= 2) {
                const node = Audio.outputAppNodes[sectionIndex - 2]
                if (node)
                    setStreamVolume(node, streamVolume(node) - 0.05)
            } else if (sectionIndex === 0 && Audio.sink?.audio)
                Audio.sink.audio.volume = Math.max(0, Audio.sink.audio.volume - 0.05)
            else if (sectionIndex === 1 && Audio.source?.audio)
                Audio.source.audio.volume = Math.max(0, Audio.source.audio.volume - 0.05)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
            if (sectionIndex >= 2) {
                const node = Audio.outputAppNodes[sectionIndex - 2]
                if (node)
                    setStreamVolume(node, streamVolume(node) + 0.05)
            } else if (sectionIndex === 0 && Audio.sink?.audio)
                Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + 0.05)
            else if (sectionIndex === 1 && Audio.source?.audio)
                Audio.source.audio.volume = Math.min(1, Audio.source.audio.volume + 0.05)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_M) {
            if (sectionIndex === 0)
                Audio.toggleMute()
            else if (sectionIndex === 1)
                Audio.toggleMicMute()
            event.accepted = true
            return true
        }
        return false
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 10
        contentHeight: col.implicitHeight
        clip: true

        ColumnLayout {
            id: col
            width: parent.width
            spacing: 8

            Text {
                text: "AUDIO · routing"
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 11
                font.bold: true
                color: "#1a8cff"
            }

            Text {
                visible: devicePickerOpen
                text: devicePickerMode === "in" ? "SELECT INPUT" : "SELECT OUTPUT"
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 10
                color: "#94a3b8"
            }

            Repeater {
                visible: devicePickerOpen
                model: devicePickerOpen ? root.pickerList() : []
                delegate: RowLayout {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    Rectangle {
                        width: 3
                        height: 18
                        visible: root.devicePickerIndex === index
                        color: "#1a8cff"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Audio.friendlyDeviceName(modelData)
                        elide: Text.ElideRight
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                        color: root.devicePickerIndex === index ? "#e0e6f0" : "#94a3b8"
                    }
                }
            }

            Text {
                visible: routePickerOpen
                text: "ROUTE STREAM TO SINK"
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 10
                color: "#94a3b8"
            }

            Repeater {
                visible: routePickerOpen
                model: routePickerOpen ? Audio.outputDevices : []
                delegate: RowLayout {
                    required property int index
                    required property var modelData
                    Layout.fillWidth: true
                    Rectangle {
                        width: 3
                        height: 18
                        visible: root.routeSinkIndex === index
                        color: "#1a8cff"
                    }
                    Text {
                        Layout.fillWidth: true
                        text: Audio.friendlyDeviceName(modelData)
                        elide: Text.ElideRight
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                        color: root.routeSinkIndex === index ? "#e0e6f0" : "#94a3b8"
                    }
                }
            }

            ColumnLayout {
                visible: !devicePickerOpen && !routePickerOpen
                Layout.fillWidth: true
                spacing: 6

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 4
                    color: root.sectionIndex === 0 ? Qt.rgba(0.1, 0.45, 1, 0.12) : "transparent"
                    border.width: root.sectionIndex === 0 ? 1 : 0
                    border.color: "#1a8cff"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "OUT: " + (Audio.friendlyDeviceName(Audio.sink) || "—")
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                        color: "#e0e6f0"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 4
                    color: root.sectionIndex === 1 ? Qt.rgba(0.1, 0.45, 1, 0.12) : "transparent"
                    border.width: root.sectionIndex === 1 ? 1 : 0
                    border.color: "#1a8cff"
                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "IN: " + (Audio.friendlyDeviceName(Audio.source) || "—")
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 10
                        color: "#e0e6f0"
                    }
                }

                Repeater {
                    model: root.streamCount
                    delegate: Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        height: 40
                        radius: 4
                        property var node: Audio.outputAppNodes[index]
                        color: root.sectionIndex === index + 2 ? Qt.rgba(0.1, 0.45, 1, 0.12) : "transparent"
                        border.width: root.sectionIndex === index + 2 ? 1 : 0
                        border.color: "#1a8cff"
                        Text {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: node ? Audio.streamPipewireLabel(node) + " · Enter route" : ""
                            elide: Text.ElideRight
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: 9
                            color: "#cbd5e1"
                        }
                    }
                }

                Text {
                    text: "j/k section · Enter picker/route · h/l vol · m mute"
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 8
                    color: "#475569"
                }
            }
        }
    }
}