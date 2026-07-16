import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"
import "../widgets"

/** CodexBar-style usage popover for Linux/Quickshell. */
FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property int _rev: CodexBarService.revision
    readonly property var providers: {
        const _r = _rev
        return CodexBarService.providers || []
    }
    readonly property var selected: {
        const _r = _rev
        return CodexBarService.selected
    }
    readonly property int selectedIndex: CodexBarService.selectedIndex
    readonly property bool loading: CodexBarService.loading

    /** 0 = provider tabs, 1 = footer actions (dashboard / refresh / status). */
    property int focusBand: 0
    property int actionIndex: 0
    readonly property int actionCount: 3

    implicitWidth: 460
    implicitHeight: 550

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    function relativeUpdated(iso) {
        if (!iso || !String(iso).length)
            return "Updated now"
        const t = Date.parse(iso)
        if (isNaN(t))
            return "Updated"
        const sec = Math.max(0, Math.floor((Date.now() - t) / 1000))
        if (sec < 60)
            return "Updated just now"
        const min = Math.floor(sec / 60)
        if (min < 60)
            return "Updated " + min + "m ago"
        const hr = Math.floor(min / 60)
        if (hr < 24)
            return "Updated " + hr + "h ago"
        return "Updated " + Math.floor(hr / 24) + "d ago"
    }

    function dashboardUrl(id) {
        if (id === "codex")
            return "https://chatgpt.com/codex/settings/usage"
        if (id === "grok")
            return "https://grok.com/?_s=usage"
        return ""
    }

    function statusUrl(id) {
        if (id === "codex")
            return "https://status.openai.com/"
        if (id === "grok")
            return "https://status.x.ai"
        return ""
    }

    function actionEnabledAt(i) {
        if (!selected)
            return false
        if (i === 0)
            return root.dashboardUrl(selected.id).length > 0
        if (i === 1)
            return !root.loading
        if (i === 2)
            return root.statusUrl(selected.id).length > 0
        return false
    }

    function triggerActionAt(i) {
        if (!actionEnabledAt(i))
            return
        if (i === 0)
            Qt.openUrlExternally(root.dashboardUrl(selected.id))
        else if (i === 1)
            CodexBarService.refresh()
        else if (i === 2)
            Qt.openUrlExternally(root.statusUrl(selected.id))
    }

    function clampActionIndex() {
        actionIndex = Math.max(0, Math.min(actionCount - 1, actionIndex))
    }

    function scrollActionIntoView() {
        const row = actionIndex === 0 ? dashboardRow
            : actionIndex === 1 ? refreshRow : statusRow
        if (!row || !detailsFlick)
            return
        const y = row.y
        const h = row.height
        const viewH = detailsFlick.height
        const top = detailsFlick.contentY
        if (y < top)
            detailsFlick.contentY = y
        else if (y + h > top + viewH)
            detailsFlick.contentY = Math.max(0, y + h - viewH)
    }

    function handleKey(event) {
        if (!open)
            return
        const t = event.text
        if (event.key === Qt.Key_Escape) {
            if (focusBand === 1) {
                focusBand = 0
                event.accepted = true
                return
            }
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
        if (t === "r") {
            CodexBarService.refresh()
            event.accepted = true
            return
        }
        if (focusBand === 0) {
            if (event.key === Qt.Key_Tab) {
                if (event.modifiers & Qt.ShiftModifier)
                    CodexBarService.selectPrev()
                else
                    CodexBarService.selectNext()
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Backtab) {
                CodexBarService.selectPrev()
                event.accepted = true
                return
            }
            if (t === "j" || event.key === Qt.Key_Down) {
                focusBand = 1
                clampActionIndex()
                Qt.callLater(scrollActionIntoView)
                event.accepted = true
                return
            }
            if (t === "k" || event.key === Qt.Key_Up) {
                CodexBarService.selectPrev()
                event.accepted = true
                return
            }
            if (t === "h" || event.key === Qt.Key_Left) {
                CodexBarService.selectPrev()
                event.accepted = true
                return
            }
            if (t === "l" || event.key === Qt.Key_Right
                    || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    focusBand = 1
                    clampActionIndex()
                    Qt.callLater(scrollActionIntoView)
                } else {
                    CodexBarService.selectNext()
                }
                event.accepted = true
                return
            }
            return
        }
        // focusBand === 1 — actions
        if (t === "k" || event.key === Qt.Key_Up) {
            if (actionIndex <= 0)
                focusBand = 0
            else
                actionIndex--
            Qt.callLater(scrollActionIntoView)
            event.accepted = true
            return
        }
        if (t === "j" || event.key === Qt.Key_Down) {
            actionIndex = Math.min(actionCount - 1, actionIndex + 1)
            Qt.callLater(scrollActionIntoView)
            event.accepted = true
            return
        }
        if (t === "h" || event.key === Qt.Key_Left) {
            focusBand = 0
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter
                || t === "l" || event.key === Qt.Key_Right) {
            triggerActionAt(actionIndex)
            event.accepted = true
        }
    }

    Keys.onPressed: event => handleKey(event)

    onOpenChanged: {
        if (open) {
            focusBand = 0
            actionIndex = 0
            CodexBarService.refresh()
            Qt.callLater(forceActiveFocus)
        }
    }

    onSelectedIndexChanged: clampActionIndex()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        // Provider tabs: icon + name + mini usage lane.
        Flickable {
            id: providerStrip
            Layout.fillWidth: true
            Layout.preferredHeight: providers.length ? 66 : 0
            contentWidth: providerRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: providers.length > 0

            Row {
                id: providerRow
                spacing: 5

                Repeater {
                    model: providers
                    delegate: Rectangle {
                        required property int index
                        required property var modelData
                        readonly property bool active: index === root.selectedIndex
                        readonly property real usageRatio: Math.max(0, Math.min(1,
                            Number(modelData.usedPercent || 0) / 100))

                        width: 82
                        height: 64
                        radius: 11
                        color: active
                            ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.9)
                            : Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                                WallustColors.moduleBackground.b, 0.48)
                        border.width: active ? 0 : 1
                        border.color: WallustColors.borderColor

                        Column {
                            anchors.fill: parent
                            anchors.margins: 7
                            spacing: 3

                            ProviderBrandIcon {
                                anchors.horizontalCenter: parent.horizontalCenter
                                providerId: modelData.id ? String(modelData.id) : ""
                                onAccent: active
                                iconSize: 20
                            }
                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: modelData.label || "?"
                                color: active ? WallustColors.moduleBackground : WallustColors.moduleText
                                font.family: Style.fontFamily
                                font.pixelSize: Style.fontPixelSize - 1
                                font.bold: active
                            }
                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: active ? Qt.rgba(0, 0, 0, 0.18)
                                    : Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                                        WallustColors.borderColor.b, 0.55)
                                Rectangle {
                                    width: parent.width * usageRatio
                                    height: parent.height
                                    radius: parent.radius
                                    color: modelData.ok
                                        ? (active ? WallustColors.moduleBackground : WallustColors.accent)
                                        : WallustColors.red
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: CodexBarService.selectIndex(index)
                        }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                WallustColors.borderColor.b, 0.4)
        }

        Text {
            Layout.fillWidth: true
            visible: providers.length === 0 && !loading
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: CodexBarService.lastError.length ? CodexBarService.lastError : "No enabled providers"
            color: WallustColors.moduleText
            opacity: 0.7
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        Flickable {
            id: detailsFlick
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: selected != null
            clip: true
            contentWidth: width
            contentHeight: details.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            ScrollBar.vertical: ScrollBar {
                policy: detailsFlick.contentHeight > detailsFlick.height
                    ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                implicitWidth: 4
            }

            Column {
                id: details
                width: detailsFlick.width - 6
                spacing: 12

                // Provider header, like the native menu's selected account heading.
                RowLayout {
                    width: parent.width
                    spacing: 8
                    ProviderBrandIcon {
                        visible: selected != null
                        providerId: (selected && selected.id) ? String(selected.id) : ""
                        iconSize: 28
                    }
                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: selected ? selected.label : ""
                            color: WallustColors.moduleText
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize + 6
                            font.bold: true
                        }
                        Text {
                            text: selected ? root.relativeUpdated(selected.updatedAt) : ""
                            color: WallustColors.moduleText
                            opacity: 0.58
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize
                        }
                    }
                    Text {
                        text: selected && selected.plan ? selected.plan : ""
                        color: WallustColors.moduleText
                        opacity: 0.65
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }
                    Text {
                        visible: loading
                        text: "\uf110"
                        color: WallustColors.accent
                        font.family: Style.fontFamily
                        RotationAnimator on rotation {
                            running: root.loading
                            from: 0; to: 360; duration: 900; loops: Animation.Infinite
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                        WallustColors.borderColor.b, 0.45)
                }

                Text {
                    width: parent.width
                    visible: selected && !selected.ok
                    wrapMode: Text.WordWrap
                    text: selected ? selected.error : ""
                    color: WallustColors.red
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                }

                Repeater {
                    model: selected && selected.ok && selected.windows ? selected.windows : []
                    delegate: UsageLane {
                        required property var modelData
                        width: details.width
                        title: modelData.windowMinutes === 300 ? "Session" : modelData.label
                        used: modelData.usedPercent
                        resetText: modelData.resetLabel
                        resetDescription: modelData.resetDescription
                    }
                }

                // Top model from local Codex logs. Not a quota lane: it is labelled explicitly.
                Rectangle {
                    width: parent.width
                    visible: selected && selected.cost && selected.cost.available
                        && selected.cost.topModel && selected.cost.topModel.length
                    height: 1
                    color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                        WallustColors.borderColor.b, 0.35)
                }
                Column {
                    width: parent.width
                    visible: selected && selected.cost && selected.cost.available
                        && selected.cost.topModel && selected.cost.topModel.length
                    spacing: 3
                    Text {
                        text: "Model"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 2
                        font.bold: true
                    }
                    Text {
                        text: (selected && selected.cost && selected.cost.topModel)
                            ? String(selected.cost.topModel) : ""
                        color: WallustColors.moduleText
                        opacity: 0.68
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                        WallustColors.borderColor.b, 0.4)
                }

                Column {
                    width: parent.width
                    spacing: 6
                    Text {
                        text: "Extra usage"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 3
                        font.bold: true
                    }
                    Rectangle {
                        width: parent.width
                        height: 9
                        radius: 4
                        color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                            WallustColors.borderColor.b, 0.3)
                    }
                    Text {
                        width: parent.width
                        text: {
                            if (!selected)
                                return ""
                            if (selected.creditsRemaining > 0)
                                return "Credits remaining: " + selected.creditsRemaining
                            if (selected.codexResetCreditsLine && selected.codexResetCreditsLine.length)
                                return selected.codexResetCreditsLine
                            return "No purchased extra credits"
                        }
                        color: WallustColors.moduleText
                        opacity: 0.68
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                        WallustColors.borderColor.b, 0.4)
                }

                Column {
                    width: parent.width
                    spacing: 6
                    Text {
                        text: "Cost"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 3
                        font.bold: true
                    }
                    Text {
                        width: parent.width
                        visible: selected && selected.cost && selected.cost.available
                        text: selected && selected.cost
                            ? "Session: " + CodexBarService.money(selected.cost.sessionCost, selected.cost.currency)
                                + " · " + CodexBarService.compactNumber(selected.cost.sessionTokens) + " tokens"
                            : ""
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }
                    Text {
                        width: parent.width
                        visible: selected && selected.cost && selected.cost.available
                        text: selected && selected.cost
                            ? "Last 30 days: " + CodexBarService.money(selected.cost.last30DaysCost, selected.cost.currency)
                                + " · " + CodexBarService.compactNumber(selected.cost.last30DaysTokens) + " tokens"
                            : ""
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }
                    Text {
                        width: parent.width
                        visible: selected && (!selected.cost || !selected.cost.available)
                        text: "Cost data unavailable from local logs"
                        color: WallustColors.moduleText
                        opacity: 0.55
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                        WallustColors.borderColor.b, 0.4)
                }

                ActionRow {
                    id: dashboardRow
                    width: details.width
                    icon: "\uf201"
                    label: "Usage Dashboard"
                    vimFocus: root.focusBand === 1 && root.actionIndex === 0
                    enabled: root.actionEnabledAt(0)
                    onTriggered: root.triggerActionAt(0)
                }
                ActionRow {
                    id: refreshRow
                    width: details.width
                    icon: "\uf021"
                    label: "Refresh"
                    vimFocus: root.focusBand === 1 && root.actionIndex === 1
                    enabled: root.actionEnabledAt(1)
                    onTriggered: root.triggerActionAt(1)
                }
                ActionRow {
                    id: statusRow
                    width: details.width
                    icon: "\uf1ea"
                    label: "Status Page"
                    vimFocus: root.focusBand === 1 && root.actionIndex === 2
                    enabled: root.actionEnabledAt(2)
                    onTriggered: root.triggerActionAt(2)
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: selected
                        ? ((selected.email || "") + (selected.source ? " · " + selected.source : "")
                            + (selected.version ? " · v" + selected.version : ""))
                        : ""
                    elide: Text.ElideMiddle
                    color: WallustColors.moduleText
                    opacity: 0.38
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                }
            }
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            visible: providers.length > 0
            text: root.focusBand === 0
                ? "h/l Tab provider · j actions · Enter · r refresh · Esc"
                : "j/k action · Enter run · h tabs · Esc back"
            color: WallustColors.moduleText
            opacity: 0.34
            font.family: Style.fontFamily
            font.pixelSize: 9
        }
    }

    component UsageLane: Column {
        id: lane
        property string title: "Usage"
        property real used: 0
        property string resetText: ""
        property string resetDescription: ""
        spacing: 5

        Text {
            text: lane.title
            color: WallustColors.moduleText
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize + 3
            font.bold: true
        }
        Rectangle {
            width: parent.width
            height: 10
            radius: 5
            color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                WallustColors.borderColor.b, 0.3)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, lane.used / 100))
                height: parent.height
                radius: parent.radius
                color: lane.used >= 85 ? WallustColors.red
                    : lane.used >= 65 ? WallustColors.yellow : WallustColors.accent
            }
        }
        RowLayout {
            width: parent.width
            Text {
                text: Math.round(lane.used) + "% used"
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
            }
            Item { Layout.fillWidth: true }
            Text {
                text: lane.resetText
                color: WallustColors.moduleText
                opacity: 0.65
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
            }
        }
        Text {
            width: parent.width
            visible: lane.resetDescription.length > 0
                && lane.resetDescription.toLowerCase().indexOf("resets") < 0
            text: lane.resetDescription
            color: WallustColors.moduleText
            opacity: 0.48
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
        }
    }

    component ActionRow: Rectangle {
        id: action
        property string icon: ""
        property string label: ""
        property bool vimFocus: false
        signal triggered()
        height: 34
        radius: 8
        color: (action.vimFocus || (actionMouse.containsMouse && action.enabled))
            ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.14)
            : "transparent"
        border.width: action.vimFocus ? 1 : 0
        border.color: WallustColors.accent
        opacity: enabled ? 1 : 0.4

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            spacing: 10
            Text {
                text: action.icon
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
            }
            Text {
                Layout.fillWidth: true
                text: action.label
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 1
            }
            Text {
                text: "›"
                color: WallustColors.moduleText
                opacity: 0.6
                font.pixelSize: Style.fontPixelSize + 3
            }
        }
        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: action.enabled
            onClicked: action.triggered()
        }
    }
}
