import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Networking
import "../singletons"
import "../widgets"

/**
 * Middle pill WiFi — vim nav, nmcli password connect for secured unknown networks.
 */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property int _tick: WifiSurfaceLogic.listRevision
    readonly property var netsSorted: {
        const _t = _tick
        return WifiSurfaceLogic.netsSorted || []
    }

    property int netIndex: 0
    property string mode: "list" // list | password | confirm | hidden

    implicitWidth: 360
    implicitHeight: Math.min(400, header.height + (pwPanel.visible ? pwPanel.height + 6 : 0) + (hiddenPanel.visible ? hiddenPanel.height + 6 : 0) + netList.height + 16)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    function currentNet() {
        if (netIndex < 0 || netIndex >= netsSorted.length)
            return null
        return netsSorted[netIndex]
    }

    function clampIndex() {
        const ns = netsSorted
        if (!ns) return
        const n = ns.length
        if (n === 0) {
            netIndex = 0
            if (mode !== "list")
                mode = "list"
            return
        }
        // When inside a network, find it by SSID to survive list reordering.
        if (mode === "hidden")
            return  // hidden mode doesn't use netIndex
        if (mode === "password" || mode === "confirm") {
            const expanded = WifiSurfaceLogic.expandedSsid
            if (!expanded) return
            const idx = ns.findIndex(net => (net.name || "") === expanded)
            if (idx >= 0) {
                netIndex = idx
                return
            }
            // Network disappeared — fall back to list.
            mode = "list"
        }
        netIndex = Math.max(0, Math.min(n - 1, netIndex))
    }

    function leaveSubMode() {
        WifiSurfaceLogic.setExpandedSsid("")
        mode = "list"
        focusListNav()
    }

    function focusListNav() {
        Qt.callLater(() => listFocusAnchor.forceActiveFocus())
    }

    function syncModeFromLogic() {
        const net = currentNet()
        if (!net)
            return
        const ssid = net.name || ""
        if (WifiSurfaceLogic.expandedSsid !== ssid) {
            if (mode !== "list")
                mode = "list"
            return
        }
        const known = WifiSurfaceLogic.knownProfiles[ssid] === true
        const confirming = WifiSurfaceLogic.netConnected(net) || known
        mode = confirming ? "confirm" : "password"
    }

    function activateRow() {
        const net = currentNet()
        if (!net || !WifiSurfaceLogic.wifiOn)
            return
        WifiSurfaceLogic.activateNetwork(net)
        syncModeFromLogic()
        if (mode === "password")
            Qt.callLater(focusPasswordField)
    }

    function focusPasswordField() {
        pwField.text = WifiSurfaceLogic.pwDraft
        pwField.forceActiveFocus()
        pwField.cursorPosition = pwField.text.length
    }

    function submitPasswordFromField() {
        if (WifiSurfaceLogic.connecting)
        return
        const n = currentNet()
        const ssid = n?.name || ""
        if (!ssid.length)
        return
        WifiSurfaceLogic.setPwDraft(pwField.text)
        if (!WifiSurfaceLogic.connectWithPassword(ssid, pwField.text))
        pwShake.restart()
    }

    function openHiddenNetwork() {
        WifiSurfaceLogic.setExpandedSsid("")
        WifiSurfaceLogic.setConnectFailed(false)
        WifiSurfaceLogic.setPwDraft("")
        mode = "hidden"
        Qt.callLater(() => {
        hiddenSsidField.text = WifiSurfaceLogic.hiddenSsidDraft
        hiddenSsidField.forceActiveFocus()
        })
    }

    function submitHiddenNetwork() {
        if (WifiSurfaceLogic.connecting)
        return
        const ssid = String(hiddenSsidField.text || "").trim()
        if (!ssid.length) {
        hiddenShake.restart()
        return
        }
        WifiSurfaceLogic.setHiddenSsidDraft(ssid)
        const pw = String(hiddenPwField.text || "").trim()
        if (!pw.length) {
        hiddenShake.restart()
        return
        }
        if (!WifiSurfaceLogic.connectWithPassword(ssid, pw))
        hiddenShake.restart()
    }

    function primaryAction() {
        const net = currentNet()
        if (!net)
            return
        if (mode === "password") {
            focusPasswordField()
            return
        }
        if (mode === "confirm") {
            if (WifiSurfaceLogic.netConnected(net))
                WifiSurfaceLogic.disconnectNetwork(net)
            else
                WifiSurfaceLogic.connectKnown(net)
            mode = "list"
            return
        }
        activateRow()
    }

    onModeChanged: {
        if (mode === "list") {
            focusListNav()
            return
        }
        if (mode === "password") {
            pwField.text = WifiSurfaceLogic.pwDraft
            Qt.callLater(focusPasswordField)
        }
        if (mode === "hidden") {
            hiddenSsidField.text = WifiSurfaceLogic.hiddenSsidDraft
            Qt.callLater(() => hiddenSsidField.forceActiveFocus())
        }
    }

    onOpenChanged: {
        WifiSurfaceLogic.onSurfaceOpenChanged(open)
        if (open) {
            netIndex = 0
            mode = "list"
            Qt.callLater(clampIndex)
            Qt.callLater(forceActiveFocus)
        }
    }

    on_TickChanged: clampIndex()

    Connections {
        target: WifiSurfaceLogic
        function onExpandedSsidChanged() {
            syncModeFromLogic()
            if (mode === "password")
                Qt.callLater(focusPasswordField)
        }
    }

    function handleKey(event) {
        if (!open)
            return
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            if (mode !== "list") {
                leaveSubMode()
                event.accepted = true
                return
            }
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (t === "j" || event.key === Qt.Key_Down) {
            netIndex = Math.min(Math.max(0, netsSorted.length - 1), netIndex + 1)
            if (mode !== "list") {
                WifiSurfaceLogic.setExpandedSsid("")
                mode = "list"
                focusListNav()
            }
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            netIndex = Math.max(0, netIndex - 1)
            if (mode !== "list") {
                WifiSurfaceLogic.setExpandedSsid("")
                mode = "list"
                focusListNav()
            }
            event.accepted = true
            return
        }
        if (t === "r") {
            WifiSurfaceLogic.scanning ? WifiSurfaceLogic.stopScan() : WifiSurfaceLogic.startScan()
            event.accepted = true
            return
        }
        if (t === "t" || t === "T") {
            if (Networking)
                Networking.wifiEnabled = !Networking.wifiEnabled
            event.accepted = true
            return
        }
        if ((t === "d" || t === "D") && mode === "list") {
            WifiSurfaceLogic.disconnectActive()
            event.accepted = true
            return
        }
        if (t === "/") {
            if (WifiSurfaceLogic.wifiOn)
                openHiddenNetwork()
            event.accepted = true
            return
        }
        if (mode === "hidden") {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                submitHiddenNetwork()
                event.accepted = true
                return
            }
            return
        }
            if (mode === "password") {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    submitPasswordFromField()
                    event.accepted = true
                    return
                }
                if (event.key === Qt.Key_Escape) {
                    leaveSubMode()
                    event.accepted = true
                    return
                }
                if (t === "l") {
                    focusPasswordField()
                    event.accepted = true
                }
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
            const net = currentNet()
            const ssid = net?.name || ""
            if (ssid.length && WifiSurfaceLogic.knownProfiles[ssid] === true) {
                WifiSurfaceLogic.forgetNetwork(ssid)
                event.accepted = true
            } else if (ssid.length) {
                WifiSurfaceLogic.showToast("No saved profile for this network")
                event.accepted = true
            }
            return
        }
        if ((t === "f" || t === "F") && mode === "confirm") {
            const net = currentNet()
            if (net?.name)
                WifiSurfaceLogic.forgetNetwork(net.name)
            leaveSubMode()
            event.accepted = true
        }
    }

    Keys.onPressed: event => handleKey(event)

    // Holds keyboard focus in list mode (TextFields keep focus in sub-modes).
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
                text: "\uf1eb"
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
            }

            Column {
                spacing: 0
                Text {
                    text: "Wi‑Fi"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 1
                    font.bold: true
                }
                    Text {
                        text: WifiSurfaceLogic.toastMessage.length
                            ? WifiSurfaceLogic.toastMessage
                            : WifiSurfaceLogic.statusText
                        color: WifiSurfaceLogic.toastMessage.length
                            ? WallustColors.accent
                            : WallustColors.moduleText
                        opacity: WifiSurfaceLogic.toastMessage.length ? 1 : 0.55
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                        font.bold: WifiSurfaceLogic.toastMessage.length > 0
                        elide: Text.ElideRight
                        width: 160
                    }
                }

                BusyIndicator {
                    visible: WifiSurfaceLogic.connecting || WifiSurfaceLogic.linkBusy
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    running: WifiSurfaceLogic.connecting || WifiSurfaceLogic.linkBusy
                }

                Item { Layout.fillWidth: true }

            Text {
                text: WifiSurfaceLogic.scanning ? "\uf110" : "\uf021"
                color: WallustColors.moduleText
                opacity: WifiSurfaceLogic.wifiOn ? 0.7 : 0.25
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                RotationAnimator on rotation {
                    running: WifiSurfaceLogic.scanning
                    from: 0
                    to: 360
                    duration: 1000
                    loops: Animation.Infinite
                }
                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    enabled: WifiSurfaceLogic.wifiOn
                    onClicked: WifiSurfaceLogic.scanning
                        ? WifiSurfaceLogic.stopScan()
                        : WifiSurfaceLogic.startScan()
                }
            }

            Rectangle {
                width: 40
                height: 22
                radius: 11
                color: WifiSurfaceLogic.wifiOn
                    ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.35)
                    : Qt.rgba(0, 0, 0, 0.25)
                border.width: 1
                border.color: WallustColors.borderColor
                Text {
                    anchors.centerIn: parent
                    text: WifiSurfaceLogic.wifiOn ? "on" : "off"
                    font.family: Style.fontFamily
                    font.pixelSize: 9
                    color: WallustColors.moduleText
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (Networking)
                            Networking.wifiEnabled = !Networking.wifiEnabled
                    }
                }
            }

        }

        Text {
            width: parent.width
            visible: !WifiSurfaceLogic.wifiOn
            horizontalAlignment: Text.AlignHCenter
            text: "Wi‑Fi is off"
            color: WallustColors.moduleText
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        Text {
            width: parent.width
            visible: WifiSurfaceLogic.wifiOn && netsSorted.length === 0
            horizontalAlignment: Text.AlignHCenter
            text: "Searching networks…"
            color: WallustColors.moduleText
            opacity: 0.55
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        Rectangle {
            id: pwPanel
            width: parent.width
            visible: root.mode === "password" && WifiSurfaceLogic.wifiOn
            radius: 10
            color: Qt.rgba(0, 0, 0, 0.22)
            implicitHeight: pwPanelCol.implicitHeight + 12

            Column {
                id: pwPanelCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 8
                spacing: 4

                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: currentNet() ? ("Password for " + (currentNet().name || "")) : "Password"
                    color: WallustColors.moduleText
                    opacity: 0.65
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 1
                }

                    Item {
                        id: pwFieldWrap
                        width: parent.width
                        height: pwField.height + 2

                        SequentialAnimation {
                            id: pwShake
                            NumberAnimation { target: pwFieldWrap; property: "x"; from: 0; to: -6; duration: 45 }
                            NumberAnimation { target: pwFieldWrap; property: "x"; from: -6; to: 6; duration: 45 }
                            NumberAnimation { target: pwFieldWrap; property: "x"; from: 6; to: 0; duration: 45 }
                        }

                        TextField {
                            id: pwField
                            width: parent.width
                            placeholderText: WifiSurfaceLogic.connectFailed
                                ? "Incorrect password"
                                : (WifiSurfaceLogic.connecting ? "Connecting…" : "Password")
                            echoMode: TextInput.Password
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize
                            color: WifiSurfaceLogic.connectFailed
                                ? WallustColors.red
                                : WallustColors.moduleText
                            font.bold: WifiSurfaceLogic.connectFailed
                            selectByMouse: true
                            readOnly: WifiSurfaceLogic.connecting
                            activeFocusOnPress: root.mode === "password"
                            onTextEdited: {
                                WifiSurfaceLogic.setPwDraft(text)
                                if (WifiSurfaceLogic.connectFailed)
                                    WifiSurfaceLogic.setConnectFailed(false)
                            }
    
                                background: Rectangle {
                                radius: 8
                                color: WifiSurfaceLogic.connectFailed
                                    ? Qt.rgba(WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.38)
                                    : Qt.rgba(0, 0, 0, 0.25)
                                border.width: WifiSurfaceLogic.connectFailed ? 2 : 1
                                border.color: WifiSurfaceLogic.connectFailed
                                    ? WallustColors.red
                                    : (WifiSurfaceLogic.connecting
                                        ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.55)
                                        : WallustColors.borderColor)
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        spacing: 8

                        BusyIndicator {
                            visible: WifiSurfaceLogic.connecting
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            running: WifiSurfaceLogic.connecting
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: WifiSurfaceLogic.connecting
                            text: "Connecting to " + (currentNet()?.name || "network") + "…"
                            color: WallustColors.accent
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize - 1
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: WifiSurfaceLogic.connectFailed && !WifiSurfaceLogic.connecting
                            text: "Wrong password — check and press Enter"
                            color: WallustColors.red
                            font.bold: true
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize
                            wrapMode: Text.WordWrap
                        }

                        Item { width: 1; height: 1 }
                        }
                }
            }

            Rectangle {
                id: hiddenPanel
                width: parent.width
                visible: root.mode === "hidden" && WifiSurfaceLogic.wifiOn
                radius: 10
                color: Qt.rgba(0, 0, 0, 0.22)
                implicitHeight: hiddenCol.implicitHeight + 12

                Column {
                    id: hiddenCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 8
                    spacing: 6

                    Text {
                        width: parent.width
                        text: "Hidden network"
                        color: WallustColors.accent
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                        font.bold: true
                    }

                    Item {
                        id: hiddenWrap
                        width: parent.width
                        height: hiddenSsidField.height + hiddenPwField.height + 6

                        SequentialAnimation {
                            id: hiddenShake
                            NumberAnimation { target: hiddenWrap; property: "x"; from: 0; to: -6; duration: 45 }
                            NumberAnimation { target: hiddenWrap; property: "x"; from: -6; to: 6; duration: 45 }
                            NumberAnimation { target: hiddenWrap; property: "x"; from: 6; to: 0; duration: 45 }
                        }

                        Column {
                            width: parent.width
                            spacing: 6

                            TextField {
                                id: hiddenSsidField
                                width: parent.width
                                placeholderText: "Network name (SSID)"
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontPixelSize
                                color: WallustColors.moduleText
                                selectByMouse: true
                                    readOnly: WifiSurfaceLogic.connecting
                                    activeFocusOnPress: root.mode === "hidden"
                                    onTextEdited: WifiSurfaceLogic.setHiddenSsidDraft(text)
                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Escape) {
                                            root.leaveSubMode()
                                            event.accepted = true
                                        }
                                    }
                                    background: Rectangle {
                                    radius: 8
                                    color: Qt.rgba(0, 0, 0, 0.25)
                                    border.width: 1
                                    border.color: WallustColors.borderColor
                                }
                            }

                            TextField {
                                id: hiddenPwField
                                width: parent.width
                                placeholderText: WifiSurfaceLogic.connectFailed
                                    ? "Incorrect password"
                                    : (WifiSurfaceLogic.connecting ? "Connecting…" : "Password")
                                echoMode: TextInput.Password
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontPixelSize
                                color: WifiSurfaceLogic.connectFailed ? WallustColors.red : WallustColors.moduleText
                                font.bold: WifiSurfaceLogic.connectFailed
                                selectByMouse: true
                                readOnly: WifiSurfaceLogic.connecting
                                onTextEdited: {
                                    if (WifiSurfaceLogic.connectFailed)
                                        WifiSurfaceLogic.setConnectFailed(false)
                                }
                                onAccepted: root.submitHiddenNetwork()
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        root.leaveSubMode()
                                        event.accepted = true
                                    }
                                }
                                background: Rectangle {
                                    radius: 8
                                    color: WifiSurfaceLogic.connectFailed
                                        ? Qt.rgba(WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.38)
                                        : Qt.rgba(0, 0, 0, 0.25)
                                    border.width: WifiSurfaceLogic.connectFailed ? 2 : 1
                                    border.color: WifiSurfaceLogic.connectFailed ? WallustColors.red : WallustColors.borderColor
                                }
                            }
                        }
                    }

                    RowLayout {
                        width: parent.width
                        BusyIndicator {
                            visible: WifiSurfaceLogic.connecting
                            Layout.preferredWidth: 18
                            Layout.preferredHeight: 18
                            running: WifiSurfaceLogic.connecting
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: WifiSurfaceLogic.connectFailed && !WifiSurfaceLogic.connecting
                            text: "Wrong password"
                            color: WallustColors.red
                            font.bold: true
                            font.family: Style.fontFamily
                        }
                        Item { width: 1; height: 1 }
                    }
                }
            }

            Connections {
                target: WifiSurfaceLogic
                function onConnectingChanged() {
                    if (!WifiSurfaceLogic.connecting && !WifiSurfaceLogic.connectFailed && root.mode === "hidden")
                        root.mode = "list"
                }
            }

            ListView {
                id: netList
            width: parent.width
            height: WifiSurfaceLogic.wifiOn
                ? Math.min(260, Math.max(40, contentHeight))
                : 0
            clip: true
            spacing: 3
            model: netsSorted
            visible: WifiSurfaceLogic.wifiOn && netsSorted.length > 0
            currentIndex: root.netIndex
            highlightMoveDuration: Motion.fast

            delegate: Column {
                id: rowCol
                required property int index
                required property var modelData

                width: netList.width
                spacing: 4

                readonly property string ssid: (modelData && modelData.name) ? modelData.name : ""
                readonly property bool isActive: WifiSurfaceLogic.netConnected(modelData)
                readonly property bool secured: WifiSurfaceLogic.isSecured(ssid)
                readonly property bool known: WifiSurfaceLogic.knownProfiles[ssid] === true
                readonly property bool rowFocused: index === root.netIndex

                Rectangle {
                    width: parent.width
                    height: 34
                    radius: 10
                    color: rowFocused
                        ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.14)
                        : (isActive ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.08) : Qt.rgba(0, 0, 0, 0.18))
                    border.width: rowFocused ? 1 : 0
                    border.color: Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.45)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: ssid.length ? ssid : "Hidden"
                            color: WallustColors.moduleText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize
                            font.bold: isActive
                        }

                        Text {
                            visible: secured
                            text: "\uf023"
                            font.family: Style.fontFamily
                            font.pixelSize: 10
                            opacity: 0.55
                            color: WallustColors.moduleText
                        }

                        WifiSignalGlyph {
                            Layout.preferredWidth: 16
                            Layout.preferredHeight: 16
                            level: (modelData && modelData.signalStrength) || 0
                            radioOn: WifiSurfaceLogic.wifiOn
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.netIndex = index
                            WifiSurfaceLogic.activateNetwork(modelData)
                            root.syncModeFromLogic()
                            if (root.mode === "password")
                                Qt.callLater(root.focusPasswordField)
                        }
                    }
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
                            text: isActive ? "Disconnect?" : "Connect saved profile"
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
                                text: isActive ? "Disconnect" : "Connect"
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
                            visible: known
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
                                        WifiSurfaceLogic.forgetNetwork(ssid)
                                        root.leaveSubMode()
                                    }
                                }
                        }
                    }
                }

            }
        }
    }
}