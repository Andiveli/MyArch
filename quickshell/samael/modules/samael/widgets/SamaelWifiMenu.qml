import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs
import qs.services
import qs.modules.common
import qs.services.network
import qs.modules.samael

Item {
    id: root
    focus: true

    // list · detail · password · advanced (802.1X vim) · filter
    property string menuMode: "list"
    property int detailFocus: 0 // 0 password, 1 advanced
    property int advancedFocus: 0 // 0 username, 1 password, 2 connect, 3 nm-editor

    property var networks: []
    property int selectedIndex: 0
    property bool vimPendingG: false
    property string filterText: ""

    readonly property var filteredNetworks: {
        const q = filterText.trim().toLowerCase()
        if (!q.length)
            return networks
        return networks.filter(n => (n.ssid || "").toLowerCase().includes(q))
    }

    readonly property var selectedAp: {
        if (selectedIndex < 0 || selectedIndex >= filteredNetworks.length)
            return null
        return filteredNetworks[selectedIndex]
    }

    function rebuildNetworks() {
        networks = Network.friendlyWifiNetworks
        if (selectedIndex >= filteredNetworks.length)
            selectedIndex = Math.max(0, filteredNetworks.length - 1)
    }

    function clearPasswordField() {
        pwField.text = ""
    }

    function moveToIndex(index) {
        const n = filteredNetworks.length
        if (n === 0)
            return
        const next = Math.max(0, Math.min(index, n - 1))
        if (next !== selectedIndex)
            clearPasswordField()
        selectedIndex = next
        list.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

        onSelectedIndexChanged: {
            clearPasswordField()
            advUserField.text = ""
            advPassField.text = ""
            if (menuMode === "advanced")
                menuMode = "detail"
        }

    function moveSelection(delta) {
        if (menuMode !== "list")
            return
        const n = filteredNetworks.length
        if (n === 0)
            return
        let next = selectedIndex + delta
        if (next < 0)
            next = n - 1
        if (next >= n)
            next = 0
        moveToIndex(next)
    }

    function openDetailForSelection(focusPasswordTyping) {
        const ap = selectedAp
        if (!ap)
            return
        clearPasswordField()
        if (!ap.isSecure && !ap.active) {
            Network.connectToWifiNetwork(ap)
            return
        }
        menuMode = focusPasswordTyping ? "password" : "detail"
        detailFocus = 0
        if (focusPasswordTyping) {
            Qt.callLater(() => pwField.forceActiveFocus())
        } else {
            root.forceActiveFocus()
        }
    }

    function openAdvanced() {
        if (!selectedAp)
            return
        clearPasswordField()
        advUserField.text = ""
        menuMode = "advanced"
        advancedFocus = 0
        forceActiveFocus()
    }

    function openNmConnectionEditor() {
        Quickshell.execDetached(["nm-connection-editor"])
    }

    function submitAdvanced() {
        const ap = selectedAp
        if (!ap)
            return
        const user = advUserField.text.trim()
        const pass = advPassField.text
        if (!user.length || !pass.length)
            return
        Network.applyEnterpriseWifi(ap, user, pass)
        menuMode = "list"
        advPassField.text = ""
        forceActiveFocus()
    }

    function submitPassword() {
        const ap = selectedAp
        if (!ap || !pwField.text.length)
            return
        if (ap.askingPassword || menuMode === "password" || menuMode === "detail") {
            Network.changePassword(ap, pwField.text)
        } else {
            Network.connectToWifiNetwork(ap)
            Network.changePassword(ap, pwField.text)
        }
    }

    function advancedMove(delta) {
        const max = 3
        advancedFocus = Math.max(0, Math.min(max, advancedFocus + delta))
    }

    function tryConnectSelected() {
        const ap = selectedAp
        if (!ap)
            return
        if (ap.active)
            return
        if (ap.isSecure) {
            openDetailForSelection(true)
            return
        }
        Network.connectToWifiNetwork(ap)
    }

    function closeMenu() {
        GlobalStates.samaelWifiMenuOpen = false
    }

    onFilterTextChanged: {
        if (selectedIndex >= filteredNetworks.length)
            selectedIndex = Math.max(0, filteredNetworks.length - 1)
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
        target: Network
        function onFriendlyWifiNetworksChanged() { root.rebuildNetworks() }
    }

    Connections {
        target: Network
        function onWifiConnectTargetChanged() {
            const t = Network.wifiConnectTarget
            if (!t?.askingPassword)
                return
            const idx = root.filteredNetworks.findIndex(n => n.ssid === t.ssid)
            if (idx >= 0 && idx !== root.selectedIndex) {
                root.selectedIndex = idx
                root.clearPasswordField()
            } else {
                root.clearPasswordField()
            }
            root.menuMode = "password"
            Qt.callLater(() => pwField.forceActiveFocus())
        }
    }

    Component.onCompleted: {
        Network.rescanWifi()
        rebuildNetworks()
    }

    implicitWidth: 320
    implicitHeight: advancedPane.visible ? 520 : (detailPane.visible ? 460 : 400)

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
                    text: "Wi-Fi"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize + 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: Network.wifiScanning ? "scanning…" : (Network.networkName || Network.wifiStatus)
                    color: WallustColors.sapphire
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize - 1
                    elide: Text.ElideLeft
                    Layout.maximumWidth: 140
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Text {
                    text: Network.wifiEnabled ? "󰤨 on" : "󰤭 off"
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize
                }
                Text {
                    text: "t toggle · d disc"
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
                onActiveFocusChanged: if (activeFocus) root.menuMode = "filter"
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.menuMode = "list"
                        root.forceActiveFocus()
                        event.accepted = true
                    }
                }
            }

            ListView {
                id: list
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: detailPane.visible ? 180 : 240
                clip: true
                spacing: 2
                model: root.filteredNetworks
                currentIndex: root.selectedIndex
                onCurrentIndexChanged: if (currentIndex >= 0)
                    root.selectedIndex = currentIndex

                delegate: Rectangle {
                    required property int index
                    required property var modelData
                    width: list.width
                    height: 34
                    radius: 8
                    color: index === root.selectedIndex ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.2)
                    border.width: index === root.selectedIndex && root.menuMode === "list" ? 1 : 0
                    border.color: WallustColors.workspaceActive

                    property var ap: modelData

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 6
                        Text {
                            text: {
                                const s = ap?.strength ?? 0
                                if (s > 80) return "󰤨"
                                if (s > 60) return "󰤥"
                                if (s > 40) return "󰤢"
                                return "󰤯"
                            }
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                            color: WallustColors.moduleText
                        }
                        Text {
                            Layout.fillWidth: true
                            text: ap?.ssid ?? "?"
                            elide: Text.ElideRight
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                        }
                        Text {
                            text: ap?.active ? "✓" : (ap?.isSecure ? "󰌾" : "")
                            color: WallustColors.workspaceActive
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.selectedIndex = index
                            root.menuMode = "list"
                            root.tryConnectSelected()
                        }
                    }
                }
            }

            ColumnLayout {
                id: detailPane
                visible: (root.menuMode === "detail" || root.menuMode === "password") && root.selectedAp
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: root.selectedAp ? ("› " + root.selectedAp.ssid) : ""
                    color: WallustColors.workspaceActive
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize
                    elide: Text.ElideRight
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: root.detailFocus === 0 && root.menuMode === "detail"
                            ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.25)
                        border.width: root.menuMode === "password" || (root.menuMode === "detail" && root.detailFocus === 0) ? 1 : 0
                        border.color: WallustColors.workspaceActive
                        Text {
                            anchors.centerIn: parent
                            text: "Password"
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize - 1
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.detailFocus = 0
                                root.menuMode = "password"
                                pwField.forceActiveFocus()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: root.detailFocus === 1 && root.menuMode === "detail"
                            ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.25)
                        border.width: root.menuMode === "detail" && root.detailFocus === 1 ? 1 : 0
                        border.color: WallustColors.workspaceActive
                        Text {
                            anchors.centerIn: parent
                            text: "Advanced"
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize - 1
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openAdvanced()
                        }
                    }
                }

                TextField {
                    id: pwField
                    Layout.fillWidth: true
                    placeholderText: "Password (802.1X → Advanced)"
                    echoMode: TextInput.Password
                    color: WallustColors.moduleText
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: SamaelStyle.fontPixelSize
                    padding: 8
                    background: Rectangle {
                        radius: 6
                        color: Qt.rgba(0, 0, 0, 0.4)
                        border.color: pwField.activeFocus ? WallustColors.workspaceActive : WallustColors.borderColor
                        border.width: pwField.activeFocus ? 2 : 1
                    }
                    onAccepted: root.submitPassword()
                    onActiveFocusChanged: if (activeFocus) root.menuMode = "password"
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.menuMode = "detail"
                            pwField.focus = false
                            root.forceActiveFocus()
                            event.accepted = true
                        }
                    }
                }

                    Text {
                        text: "Enter/l → password · h/l · a/Enter → 802.1X panel · Esc back"
                        color: WallustColors.sapphire
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 8
                    }
                }

                ColumnLayout {
                    id: advancedPane
                    visible: root.menuMode === "advanced" && root.selectedAp
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.selectedAp ? ("802.1X · " + root.selectedAp.ssid) : ""
                        color: WallustColors.workspaceActive
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: SamaelStyle.fontPixelSize
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: "PEAP (campus/oficina). TLS u otro EAP → última fila."
                        color: WallustColors.sapphire
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 8
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: root.advancedFocus === 0 ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.25)
                        border.width: root.advancedFocus === 0 ? 1 : 0
                        border.color: WallustColors.workspaceActive
                        TextField {
                            id: advUserField
                            anchors.fill: parent
                            anchors.margins: 4
                            placeholderText: "Username / identity"
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                            background: Item {}
                            onActiveFocusChanged: if (activeFocus) root.advancedFocus = 0
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.menuMode = "detail"
                                    focus = false
                                    root.forceActiveFocus()
                                    event.accepted = true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 32
                        radius: 8
                        color: root.advancedFocus === 1 ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.25)
                        border.width: root.advancedFocus === 1 ? 1 : 0
                        border.color: WallustColors.workspaceActive
                        TextField {
                            id: advPassField
                            anchors.fill: parent
                            anchors.margins: 4
                            placeholderText: "Password"
                            echoMode: TextInput.Password
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize
                            background: Item {}
                            onActiveFocusChanged: if (activeFocus) root.advancedFocus = 1
                            onAccepted: root.submitAdvanced()
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    root.menuMode = "detail"
                                    focus = false
                                    root.forceActiveFocus()
                                    event.accepted = true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 30
                        radius: 8
                        color: root.advancedFocus === 2 ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.35)
                        border.width: root.advancedFocus === 2 ? 1 : 0
                        border.color: WallustColors.workspaceActive
                        Text {
                            anchors.centerIn: parent
                            text: "Connect (PEAP)"
                            color: WallustColors.moduleText
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: SamaelStyle.fontPixelSize - 1
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.submitAdvanced()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 28
                        radius: 8
                        color: root.advancedFocus === 3 ? WallustColors.buttonHover : Qt.rgba(0, 0, 0, 0.2)
                        border.width: root.advancedFocus === 3 ? 1 : 0
                        border.color: WallustColors.borderColor
                        Text {
                            anchors.centerIn: parent
                            text: "nm-connection-editor…"
                            color: WallustColors.buttonHover
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: 8
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.openNmConnectionEditor()
                        }
                    }

                    Text {
                        text: "j/k filas · Enter edit/connect · Esc → detail"
                        color: WallustColors.sapphire
                        font.family: SamaelStyle.fontFamily
                        font.pixelSize: 8
                    }
                }

                Text {
                    text: "list: j/k Enter/l · detail: h/l · advanced: j/k · Esc · r scan"
                color: WallustColors.buttonHover
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 8
            }
        }
    }

    Keys.onPressed: event => {
        const text = event.text
        const key = event.key

        if (menuMode === "password" && pwField.activeFocus)
            return
        if (menuMode === "advanced" && (advUserField.activeFocus || advPassField.activeFocus))
            return

        if (key === Qt.Key_Escape) {
            if (menuMode === "password") {
                menuMode = "detail"
                pwField.focus = false
                forceActiveFocus()
            } else if (menuMode === "advanced") {
                menuMode = "detail"
                advUserField.focus = false
                advPassField.focus = false
                forceActiveFocus()
            } else if (menuMode === "detail" || menuMode === "filter") {
                menuMode = "list"
                forceActiveFocus()
            } else {
                closeMenu()
            }
            event.accepted = true
            return
        }

        if (key === Qt.Key_Slash && menuMode === "list") {
            filterField.forceActiveFocus()
            event.accepted = true
            return
        }

            if (menuMode === "advanced") {
                if (text === "j" || key === Qt.Key_Down) {
                    advancedMove(1)
                    event.accepted = true
                    return
                }
                if (text === "k" || key === Qt.Key_Up) {
                    advancedMove(-1)
                    event.accepted = true
                    return
                }
                if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                    if (advancedFocus === 0)
                        advUserField.forceActiveFocus()
                    else if (advancedFocus === 1)
                        advPassField.forceActiveFocus()
                    else if (advancedFocus === 2)
                        submitAdvanced()
                    else
                        openNmConnectionEditor()
                    event.accepted = true
                    return
                }
            }

            if (menuMode === "detail") {
                if (text === "h" || key === Qt.Key_Left) {
                detailFocus = 0
                event.accepted = true
                return
            }
            if (text === "l" || key === Qt.Key_Right) {
                detailFocus = 1
                event.accepted = true
                return
            }
            if (text === "j" || key === Qt.Key_Down) {
                detailFocus = 1
                event.accepted = true
                return
            }
            if (text === "k" || key === Qt.Key_Up) {
                detailFocus = 0
                event.accepted = true
                return
            }
            if (key === Qt.Key_Return || key === Qt.Key_Enter) {
                if (detailFocus === 0) {
                    menuMode = "password"
                    pwField.forceActiveFocus()
                } else {
                    openAdvanced()
                }
                event.accepted = true
                return
            }
            if (text === "a" || key === Qt.Key_A) {
                openAdvanced()
                event.accepted = true
                return
            }
        }

        if (menuMode === "list") {
            if (key === Qt.Key_Return || key === Qt.Key_Enter || text === "l") {
                tryConnectSelected()
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
                moveToIndex(filteredNetworks.length - 1)
                event.accepted = true
                return
            }
            if (text === "r" || key === Qt.Key_R) {
                Network.rescanWifi()
                event.accepted = true
                return
            }
            if (text === "t" || key === Qt.Key_T) {
                Network.toggleWifi()
                event.accepted = true
                return
            }
            if (text === "d" || key === Qt.Key_D) {
                Network.disconnectWifiNetwork()
                event.accepted = true
            }
        }
    }

    Connections {
        target: GlobalStates
        function onSamaelWifiMenuOpenChanged() {
            if (GlobalStates.samaelWifiMenuOpen) {
                menuMode = "list"
                advancedFocus = 0
                Network.rescanWifi()
                rebuildNetworks()
                pwField.text = ""
                advUserField.text = ""
                advPassField.text = ""
                root.forceActiveFocus()
            }
        }
    }
}