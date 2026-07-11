import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"

/**
 * Middle pill Bluetooth — vim nav, Quickshell.Bluetooth + bluetoothctl pair for new devices.
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property int _tick: BtSurfaceLogic.listRevision
    readonly property var devicesSorted: {
        const _t = _tick
        return BtSurfaceLogic.devicesSorted || []
    }

    property int devIndex: 0
    property string mode: "list" // list | confirm

    implicitWidth: 360
    implicitHeight: Math.min(400, header.height + devList.height + 24)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    function currentDevice() {
        if (devIndex < 0 || devIndex >= devicesSorted.length)
            return null
        return devicesSorted[devIndex]
    }

    function clampIndex() {
        const ns = devicesSorted
        if (!ns) return
        const n = ns.length
        if (n === 0) {
            devIndex = 0
            mode = "list"
            return
        }
        devIndex = Math.max(0, Math.min(n - 1, devIndex))
        const d = currentDevice()
        const addr = d?.address || ""
        if (mode === "confirm" && BtSurfaceLogic.expandedAddress !== addr)
            mode = "list"
    }

    function leaveConfirm() {
        BtSurfaceLogic.setExpandedAddress("")
        mode = "list"
        focusListNav()
    }

    function focusListNav() {
        Qt.callLater(() => listFocusAnchor.forceActiveFocus())
    }

    function syncModeFromLogic() {
        const d = currentDevice()
        if (!d)
            return
        const addr = d.address || ""
        if (BtSurfaceLogic.expandedAddress === addr && (d.connected || d.paired))
            mode = "confirm"
        else if (mode === "confirm")
            mode = "list"
    }

    function activateRow() {
        const d = currentDevice()
        if (!d || !BtSurfaceLogic.btOn)
            return
        BtSurfaceLogic.activateDevice(d)
        syncModeFromLogic()
    }

    function primaryAction() {
        const d = currentDevice()
        if (!d)
            return
        if (mode === "confirm") {
            if (d.connected)
                BtSurfaceLogic.disconnectDevice(d)
            else
                BtSurfaceLogic.connectDevice(d)
            leaveConfirm()
            return
        }
        activateRow()
    }

    onOpenChanged: {
        BtSurfaceLogic.onSurfaceOpenChanged(open)
        if (open) {
            devIndex = 0
            mode = "list"
            Qt.callLater(clampIndex)
            Qt.callLater(forceActiveFocus)
        }
    }

    on_TickChanged: clampIndex()

    Connections {
        target: BtSurfaceLogic
        function onExpandedAddressChanged() {
            syncModeFromLogic()
        }
    }

    function handleKey(event) {
        if (!open)
            return
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            if (mode !== "list") {
                leaveConfirm()
                event.accepted = true
                return
            }
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (t === "j" || event.key === Qt.Key_Down) {
            devIndex = Math.min(Math.max(0, devicesSorted.length - 1), devIndex + 1)
            if (mode !== "list")
                leaveConfirm()
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            devIndex = Math.max(0, devIndex - 1)
            if (mode !== "list")
                leaveConfirm()
            event.accepted = true
            return
        }
        if (t === "r") {
            BtSurfaceLogic.toggleScan()
            event.accepted = true
            return
        }
        if (t === "t" || t === "T") {
            BtSurfaceLogic.toggleRadio()
            event.accepted = true
            return
        }
        if ((t === "d" || t === "D") && mode === "list") {
            BtSurfaceLogic.disconnectActive()
            event.accepted = true
            return
        }
        if (t === "l" || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            primaryAction()
            event.accepted = true
            return
        }
        if (t === "o") {
            activateRow()
            event.accepted = true
            return
        }
        if ((t === "f" || t === "F") && mode === "list") {
            const d = currentDevice()
            if (d && d.paired) {
                BtSurfaceLogic.forgetDevice(d)
                event.accepted = true
            } else if (d) {
                BtSurfaceLogic.showToast("Device is not paired")
                event.accepted = true
            }
            return
        }
        if ((t === "f" || t === "F") && mode === "confirm") {
            const d = currentDevice()
            if (d)
                BtSurfaceLogic.forgetDevice(d)
            leaveConfirm()
            event.accepted = true
        }
        if ((t === "a" || t === "A") && mode === "list") {
            const d = currentDevice()
            if (d && d.connected)
                BtSurfaceLogic.routeAudioToDevice(d)
            else if (d)
                BtSurfaceLogic.showToast("Connect the device first")
            event.accepted = true
        }
    }

    Keys.onPressed: event => handleKey(event)

    Item {
        id: listFocusAnchor
        width: 1
        height: 1
        focus: root.open && root.mode === "list"
        Keys.onPressed: event => root.handleKey(event)
    }

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            id: header
            width: parent.width
            spacing: 8

            Text {
                text: "\uf294"
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
            }

            Column {
                spacing: 0
                Text {
                    text: "Bluetooth"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 1
                    font.bold: true
                }
                Text {
                    text: BtSurfaceLogic.toastMessage.length
                        ? BtSurfaceLogic.toastMessage
                        : BtSurfaceLogic.statusText
                    color: BtSurfaceLogic.toastMessage.length
                        ? WallustColors.accent
                        : WallustColors.moduleText
                    opacity: BtSurfaceLogic.toastMessage.length ? 1 : 0.55
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                    font.bold: BtSurfaceLogic.toastMessage.length > 0
                    elide: Text.ElideRight
                    width: 160
                }
            }

            BusyIndicator {
                visible: BtSurfaceLogic.linkBusy || BtSurfaceLogic.pairingAddress.length > 0
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
                running: BtSurfaceLogic.linkBusy || BtSurfaceLogic.pairingAddress.length > 0
            }

            Item { Layout.fillWidth: true }

            Text {
                text: BtSurfaceLogic.discovering ? "\uf110" : "\uf021"
                color: WallustColors.moduleText
                opacity: BtSurfaceLogic.btOn ? 0.7 : 0.25
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                RotationAnimator on rotation {
                    running: BtSurfaceLogic.discovering
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: BtSurfaceLogic.btOn
                    onClicked: BtSurfaceLogic.toggleScan()
                }
            }

            Rectangle {
                width: 40
                height: 22
                radius: 11
                color: BtSurfaceLogic.btOn
                    ? Qt.rgba(0.42, 0.68, 0.46, 0.42)
                    : Qt.rgba(0, 0, 0, 0.25)
                border.width: 1
                border.color: BtSurfaceLogic.btOn
                    ? Qt.rgba(0.48, 0.72, 0.52, 0.55)
                    : WallustColors.borderColor

                Rectangle {
                    x: BtSurfaceLogic.btOn ? parent.width - width - 2 : 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 18
                    height: 18
                    radius: 9
                    color: BtSurfaceLogic.btOn
                        ? Qt.rgba(0.75, 0.92, 0.78, 1)
                        : WallustColors.moduleText
                    Behavior on x { NumberAnimation { duration: Motion.fast } }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: BtSurfaceLogic.toggleRadio()
                }
            }
        }

        Text {
            width: parent.width
            visible: !BtSurfaceLogic.btOn
            horizontalAlignment: Text.AlignHCenter
            text: "Bluetooth is off"
            color: WallustColors.moduleText
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        Text {
            width: parent.width
            visible: BtSurfaceLogic.btOn && devicesSorted.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: BtSurfaceLogic.discovering ? "Scanning…" : "No devices found"
            color: WallustColors.moduleText
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        ListView {
            id: devList
            width: parent.width
            height: BtSurfaceLogic.btOn
                ? Math.min(280, Math.max(40, contentHeight))
                : 0
            clip: true
            spacing: 3
            model: devicesSorted
            visible: BtSurfaceLogic.btOn && devicesSorted.length > 0
            currentIndex: root.devIndex
            highlightMoveDuration: Motion.fast

            delegate: Column {
                id: rowCol
                required property int index
                required property var modelData

                width: devList.width
                spacing: 4

                readonly property string addr: (modelData && modelData.address) ? modelData.address : ""
                readonly property bool isConnected: modelData ? modelData.connected === true : false
                readonly property bool isPaired: modelData ? modelData.paired === true : false
                readonly property bool rowFocused: index === root.devIndex
                readonly property bool pairing: BtSurfaceLogic.isPairing(modelData)
                readonly property bool busy: BtSurfaceLogic.deviceBusy(modelData)
                readonly property bool failed: BtSurfaceLogic.isFailed(modelData)
                readonly property int battery: BtSurfaceLogic.batteryLevel(modelData)

                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 10
                    color: rowFocused
                        ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.14)
                        : (isConnected ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.08) : Qt.rgba(0, 0, 0, 0.18))
                    border.width: rowFocused ? 1 : 0
                    border.color: Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.45)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            text: "\uf294"
                            font.family: Style.fontFamily
                            font.pixelSize: 12
                            color: isConnected ? WallustColors.accent : WallustColors.moduleText
                            opacity: isConnected ? 1 : 0.55
                        }

                        Column {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: BtSurfaceLogic.deviceLabel(modelData)
                                color: WallustColors.moduleText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontPixelSize
                                font.bold: isConnected
                            }
                            Text {
                                width: parent.width
                                visible: text.length > 0
                                elide: Text.ElideRight
                                text: BtSurfaceLogic.metaFor(modelData)
                                color: WallustColors.moduleText
                                opacity: 0.45
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontPixelSize - 2
                            }
                        }

                        BusyIndicator {
                            visible: pairing || busy
                            Layout.preferredWidth: 14
                            Layout.preferredHeight: 14
                            running: pairing || busy
                        }

                        Text {
                            visible: isConnected && battery >= 0
                            text: battery + "%"
                            color: WallustColors.moduleText
                            opacity: 0.6
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize - 2
                        }

                        Rectangle {
                            visible: !isPaired && !pairing
                            radius: 8
                            color: Qt.rgba(0, 0, 0, 0.2)
                            implicitWidth: pairLbl.implicitWidth + 14
                            implicitHeight: 22
                            Text {
                                id: pairLbl
                                anchors.centerIn: parent
                                text: "Pair"
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                color: WallustColors.accent
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.devIndex = index
                            BtSurfaceLogic.activateDevice(modelData)
                            root.syncModeFromLogic()
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: failed
                    leftPadding: 12
                    text: "Pairing failed"
                    color: WallustColors.red
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                }

                Rectangle {
                    width: parent.width
                    visible: rowFocused && root.mode === "confirm"
                    radius: 10
                    color: Qt.rgba(0, 0, 0, 0.22)
                    implicitHeight: confirmRow.implicitHeight + 12

                    RowLayout {
                        id: confirmRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 8
                        spacing: 6

                        Text {
                            Layout.fillWidth: true
                            text: isConnected ? "Disconnect?" : "Connect?"
                            color: WallustColors.moduleText
                            opacity: 0.7
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize - 1
                        }

                        Rectangle {
                            radius: 8
                            color: Style.hoverColor
                            implicitWidth: btn1.implicitWidth + 16
                            implicitHeight: 24
                            Text {
                                id: btn1
                                anchors.centerIn: parent
                                text: isConnected ? "Disconnect" : "Connect"
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                color: WallustColors.moduleText
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.primaryAction()
                            }
                        }

                        Rectangle {
                            visible: isPaired
                            radius: 8
                            color: Qt.rgba(WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.2)
                            implicitWidth: btnF.implicitWidth + 16
                            implicitHeight: 24
                            Text {
                                id: btnF
                                anchors.centerIn: parent
                                text: "Forget"
                                font.family: Style.fontFamily
                                font.pixelSize: 10
                                color: WallustColors.red
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    BtSurfaceLogic.forgetDevice(modelData)
                                    root.leaveConfirm()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}