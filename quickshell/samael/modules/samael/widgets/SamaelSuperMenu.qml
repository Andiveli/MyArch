import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs
import qs.services
import qs.services.network
import qs.modules.common
import qs.modules.samael
import Quickshell.Hyprland

Item {
    id: root
    implicitWidth: card.width
    implicitHeight: card.height

    readonly property color accent: WallustColors.sapphire
    readonly property color ink: WallustColors.moduleText
    readonly property color inkMuted: WallustColors.buttonHover
    readonly property color sep: WallustColors.borderColor
    readonly property int cornerRadius: 12
    readonly property int gridCols: quickExpanded ? 1 : 3
    readonly property bool quickExpanded: expandedKey !== ""

    readonly property var tiles: [
        { key: "battery", label: "BATTERY", expandable: true },
        { key: "audio", label: "AUDIO", expandable: true },
        { key: "network", label: "NETWORK", expandable: true },
        { key: "weather", label: "WEATHER", expandable: true },
        { key: "display", label: "DISPLAY", expandable: true },
        { key: "theme", label: "THEME", expandable: true },
        { key: "system", label: "SYSTEM", expandable: false },
        { key: "calendar", label: "CALENDAR", expandable: true },
        { key: "power", label: "POWER", expandable: true },
    ]

    property int selectedIndex: 0
    property string expandedKey: ""
    property string weatherSubtitle: ""

    readonly property var expandedTile: {
        for (let i = 0; i < tiles.length; i++) {
            if (tiles[i].key === expandedKey)
                return tiles[i]
        }
        return null
    }

    function tileDyn(key: string): var {
        const pct = Battery.available ? Math.round(Battery.percentage * 100) : -1
        const chargeTag = Battery.isCharging ? " · CHARGING"
            : Battery.isFull ? " · FULL"
            : Battery.isPluggedIn ? " · PLUGGED" : ""
        const rateW = Battery.available && Battery.energyRate
            ? Math.abs(Battery.energyRate) / 1e6 : 0
        const watts = rateW >= 0.05 ? `  ${rateW.toFixed(1)}W` : ""

        switch (key) {
        case "battery":
            return {
                glyph: pct < 0 ? "󰁹" : (Battery.isCharging ? "󰂄" : pct <= 15 ? "󰁺" : pct <= 35 ? "󰁻" : "󰁽"),
                label: "BATTERY",
                sub: pct < 0 ? "AC / NO BAT" : `${pct}%${chargeTag}${watts}`,
                tone: pct >= 0 && pct <= 15 ? WallustColors.workspaceUrgent : ink
            }
        case "audio": {
            const v = Math.round((Audio.sink?.audio?.volume ?? 0) * 100)
            const muted = Audio.sink?.audio?.muted
            return {
                glyph: muted ? "󰝟" : (v === 0 ? "󰕿" : v < 50 ? "󰖀" : "󰕾"),
                label: "AUDIO",
                sub: !Audio.ready ? "—" : (muted ? "MUTED" : `${v}% · ${Audio.friendlyDeviceName(Audio.sink)}`),
                tone: muted ? WallustColors.workspaceUrgent : ink
            }
        }
        case "network": {
            if (Network.ethernet)
                return { glyph: "󰈀", label: "ETHERNET", sub: "CONNECTED", tone: ink }
            if (Network.active) {
                const sig = Network.active.strength !== undefined ? ` · ${Network.active.strength}%` : ""
                return {
                    glyph: "󰤨",
                    label: "WI-FI",
                    sub: (Network.active.ssid || "(hidden)") + sig,
                    tone: ink
                }
            }
            return {
                glyph: "󰤭",
                label: "OFFLINE",
                sub: Network.wifiStatus || "—",
                tone: inkMuted
            }
        }
        case "weather":
            return {
                glyph: weatherSubtitle.length ? "󰖕" : "󰖔",
                label: "WEATHER",
                sub: weatherSubtitle.length ? weatherSubtitle : "Loading…",
                tone: ink
            }
        case "display": {
            const mon = Brightness.getMonitorForScreen(
                Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0])
            const b = mon?.ready ? Math.round(mon.brightness * 100) : -1
            return {
                glyph: "󰍹",
                label: "DISPLAY",
                sub: b >= 0 ? `${b}% · ${mon.name || "monitor"}` : "brightnessctl —",
                tone: ink
            }
        }
        case "theme":
            return { glyph: "󰸌", label: "THEME", sub: "WALLPAPER · WALLUST", tone: ink }
        case "system":
            return { glyph: "󰘚", label: "SYSTEM", sub: "OPEN OVERVIEW", tone: accent }
        case "calendar": {
            const d = new Date()
            return {
                glyph: "󰃭",
                label: "CALENDAR",
                sub: d.toLocaleDateString(Qt.locale(), "dddd · dd MMM"),
                tone: ink
            }
        }
        case "power":
            return { glyph: "󰐥", label: "POWER", sub: "SESSION", tone: ink }
        default:
            return { glyph: "󰋼", label: key.toUpperCase(), sub: "", tone: ink }
        }
    }

    function moveGrid(dr: int, dc: int) {
        const n = tiles.length
        const cols = gridCols
        let row = Math.floor(selectedIndex / cols)
        let col = selectedIndex % cols
        const maxRow = Math.floor((n - 1) / cols)
        row = Math.max(0, Math.min(maxRow, row + dr))
        col = Math.max(0, Math.min(cols - 1, col + dc))
        let idx = row * cols + col
        if (idx >= n)
            idx = n - 1
        selectedIndex = idx
    }

    function expandTile(key: string) {
        if (!key) {
            expandedKey = ""
            return
        }
        expandedKey = expandedKey === key ? "" : key
    }

    function activateSelected() {
        const t = tiles[selectedIndex]
        if (!t)
            return
        if (t.key === "system") {
            SamaelBarNavHub.openSystemSidebarFromSuperMenu()
            return
        }
        if (t.expandable)
            expandTile(t.key)
    }

    function handleKey(event) {
        if (event.key === Qt.Key_Escape) {
            if (expandedKey !== "") {
                expandedKey = ""
                event.accepted = true
                return
            }
            GlobalStates.samaelSuperMenuOpen = false
            event.accepted = true
            return
        }
        if (expandedKey !== "" && detailLoader.item && typeof detailLoader.item.handleKey === "function") {
            if (detailLoader.item.handleKey(event)) {
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_J || event.key === Qt.Key_K || event.key === Qt.Key_H || event.key === Qt.Key_L
                || event.key === Qt.Key_Up || event.key === Qt.Key_Down || event.key === Qt.Key_Left || event.key === Qt.Key_Right
                || event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_M)
                return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateSelected()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            moveGrid(1, 0)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            moveGrid(-1, 0)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_H || event.key === Qt.Key_Left) {
            if (!quickExpanded)
                moveGrid(0, -1)
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_L || event.key === Qt.Key_Right) {
            if (!quickExpanded)
                moveGrid(0, 1)
            event.accepted = true
        }
    }

    Keys.onPressed: event => root.handleKey(event)
    focus: true

    Rectangle {
        id: card
        width: 640
        height: Math.min(Math.max(bodyRow.implicitHeight + 56, quickExpanded ? 420 : 380), 520)
        color: SamaelStyle.menuPanelFill
        border.color: sep
        border.width: 1
        radius: cornerRadius

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 17
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "CONTROL CENTER"
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 13
                    font.letterSpacing: 2
                    font.bold: true
                    color: accent
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: quickExpanded ? "tile detail" : "quick panel"
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 9
                    font.letterSpacing: 1
                    color: inkMuted
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: sep }

            RowLayout {
                id: bodyRow
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Item {
                    id: quickGrid
                    Layout.preferredWidth: quickExpanded ? 72 : 300
                    Layout.fillHeight: true
                    readonly property int tileH: quickExpanded ? 44 : 92
                    readonly property int spacing: quickExpanded ? 4 : 10
                    readonly property int cols: root.gridCols
                    readonly property real tileW: cols > 0
                        ? (width - (cols - 1) * spacing) / cols
                        : width

                    implicitHeight: {
                        const rows = Math.ceil(tiles.length / cols)
                        return rows * tileH + Math.max(0, rows - 1) * spacing
                    }

                    Grid {
                        anchors.top: parent.top
                        anchors.left: parent.left
                        width: parent.width
                        columns: quickGrid.cols
                        rowSpacing: quickGrid.spacing
                        columnSpacing: quickGrid.spacing

                        Repeater {
                            model: root.tiles
                            delegate: Item {
                                required property int index
                                required property var modelData
                                width: quickGrid.tileW
                                height: quickGrid.tileH
                                readonly property var dyn: root.tileDyn(modelData.key)
                                readonly property bool selected: root.selectedIndex === index

                                Rectangle {
                                    anchors.fill: parent
                                    radius: root.cornerRadius - 4
                                    color: selected
                                        ? Qt.rgba(accent.r, accent.g, accent.b, 0.12)
                                        : Qt.rgba(0, 0, 0, 0.22)
                                    border.width: selected ? 2 : 1
                                    border.color: selected ? accent : sep
                                }

                                Column {
                                    anchors.fill: parent
                                    anchors.margins: quickExpanded ? 4 : 10
                                    spacing: quickExpanded ? 0 : 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: dyn.glyph
                                        color: dyn.tone
                                        font.family: SamaelStyle.fontFamily
                                        font.pixelSize: quickExpanded ? 16 : 26
                                    }
                                    Text {
                                        visible: !quickExpanded
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: dyn.label
                                        color: ink
                                        font.family: SamaelStyle.fontFamily
                                        font.pixelSize: 9
                                        font.letterSpacing: 1.2
                                        font.weight: Font.Medium
                                    }
                                    Text {
                                        visible: !quickExpanded
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        elide: Text.ElideRight
                                        text: dyn.sub
                                        color: inkMuted
                                        font.family: SamaelStyle.fontFamily
                                        font.pixelSize: 8
                                        font.letterSpacing: 0.6
                                        opacity: 0.9
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        root.selectedIndex = index
                                        if (modelData.key === "system")
                                            SamaelBarNavHub.openSystemSidebarFromSuperMenu()
                                        else if (modelData.expandable)
                                            root.expandTile(modelData.key)
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: quickExpanded
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    Layout.leftMargin: 14
                    Layout.rightMargin: 14
                    color: sep
                }

                ColumnLayout {
                    visible: quickExpanded
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        Text {
                            text: root.expandedTile ? root.tileDyn(root.expandedTile.key).glyph : ""
                            font.family: SamaelStyle.fontFamily
                            font.pixelSize: 28
                            color: root.expandedTile ? root.tileDyn(root.expandedTile.key).tone : ink
                        }
                        Column {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                width: parent.width
                                text: root.expandedTile ? root.tileDyn(root.expandedTile.key).label : ""
                                color: ink
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: 13
                                font.letterSpacing: 2
                                font.weight: Font.Medium
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: root.expandedTile ? root.tileDyn(root.expandedTile.key).sub : ""
                                color: inkMuted
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                            }
                        }
                        Rectangle {
                            width: 26
                            height: 26
                            radius: 13
                            color: closeMa.containsMouse ? Qt.rgba(0, 0, 0, 0.25) : "transparent"
                            border.color: sep
                            border.width: 1
                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                font.family: SamaelStyle.fontFamily
                                font.pixelSize: 16
                                color: inkMuted
                            }
                            MouseArea {
                                id: closeMa
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.expandedKey = ""
                            }
                        }
                    }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentWidth: width
                            contentHeight: detailLoader.detailContentHeight
                            boundsBehavior: Flickable.StopAtBounds

                            Loader {
                                id: detailLoader
                                width: parent.width
                                active: root.expandedKey !== ""
                                readonly property real detailContentHeight: item
                                    ? (item.implicitHeight > 0 ? item.implicitHeight : 320)
                                    : 0
                                height: detailContentHeight
                            source: {
                                switch (root.expandedKey) {
                                case "power": return "supermenu/SuperMenuPowerBody.qml"
                                case "calendar": return "supermenu/SuperMenuCalendarBody.qml"
                                case "battery": return "supermenu/SuperMenuBatteryBody.qml"
                                case "audio": return "supermenu/SuperMenuAudioBody.qml"
                                case "network": return "supermenu/SuperMenuNetworkBody.qml"
                                case "weather": return "supermenu/SuperMenuWeatherBody.qml"
                                case "display": return "supermenu/SuperMenuDisplayBody.qml"
                                case "theme": return "supermenu/SuperMenuThemeBody.qml"
                                default: return "supermenu/SuperMenuPlaceholderBody.qml"
                                }
                            }
                            onLoaded: {
                                if (item && item.weatherLine !== undefined)
                                    item.weatherLine = root.weatherSubtitle
                            }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: quickExpanded
                    ? "j/k tiles · Enter · detail keys · Esc back"
                    : "j/k/h/l · Enter expand · SYSTEM → overview · Esc close"
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 9
                color: Qt.rgba(1, 1, 1, 0.4)
            }
        }
    }

    Process {
        running: GlobalStates.samaelSuperMenuOpen
        command: ["bash", "/home/samael/.config/hypr/UserScripts/WeatherWrap.sh"]
        stdout: SplitParser {
            onRead: data => {
                const raw = data.trim()
                if (!raw.length)
                    return
                try {
                    const j = JSON.parse(raw)
                    root.weatherSubtitle = (j.text ?? "").trim()
                } catch (e) { /* ignore */ }
            }
        }
    }
}