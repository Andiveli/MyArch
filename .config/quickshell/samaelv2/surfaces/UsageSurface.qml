import QtQuick
import QtQuick.Layouts
import "../singletons"

/**
 * Middle pill — CodexBar usage detail. Tab cycles providers; Esc closes.
 */
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

    implicitWidth: 360
    implicitHeight: Math.min(340, column.implicitHeight + 16)

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    enabled: open
    focus: open

    onOpenChanged: {
        if (open) {
            CodexBarService.refresh()
            Qt.callLater(forceActiveFocus)
        }
    }

    function handleKey(event) {
        if (!open)
            return
        if (event.key === Qt.Key_Escape) {
            ShellActions.closeMiddleSurface?.()
            event.accepted = true
            return
        }
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
        const t = event.text
        if (t === "j" || event.key === Qt.Key_Down) {
            CodexBarService.selectNext()
            event.accepted = true
            return
        }
        if (t === "k" || event.key === Qt.Key_Up) {
            CodexBarService.selectPrev()
            event.accepted = true
            return
        }
        if (t === "r") {
            CodexBarService.refresh()
            event.accepted = true
        }
    }

    Keys.onPressed: event => handleKey(event)

    Column {
        id: column
        anchors.fill: parent
        anchors.margins: 10
        spacing: 8

        RowLayout {
            width: parent.width
            spacing: 8

            Text {
                text: "\uf201"
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 2
            }

            Column {
                Layout.fillWidth: true
                spacing: 1
                Text {
                    text: "Usage"
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 1
                    font.bold: true
                }
                Text {
                    text: loading ? "Refreshing…" : (providers.length + " provider" + (providers.length === 1 ? "" : "s") + " · Tab")
                    color: WallustColors.moduleText
                    opacity: 0.55
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                }
            }

            Text {
                visible: loading
                text: "\uf110"
                color: WallustColors.moduleText
                opacity: 0.6
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                RotationAnimator on rotation {
                    running: root.loading
                    from: 0
                    to: 360
                    duration: 900
                    loops: Animation.Infinite
                }
            }
        }

        Text {
            width: parent.width
            visible: providers.length === 0 && !loading
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: CodexBarService.lastError.length
                ? CodexBarService.lastError
                : "No enabled providers\n(codexbar config enable --provider …)"
            color: WallustColors.moduleText
            opacity: 0.6
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
        }

        // Provider strip (tabs)
        Flickable {
            id: stripFlick
            width: parent.width
            height: providers.length ? 28 : 0
            contentWidth: stripRow.implicitWidth
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: providers.length > 0

            Row {
                id: stripRow
                spacing: 6

                Repeater {
                    model: providers

                    Rectangle {
                        required property int index
                        required property var modelData

                        readonly property bool active: index === root.selectedIndex

                        height: 26
                        radius: 8
                        implicitWidth: tabLabel.implicitWidth + 16
                        color: active
                            ? Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.22)
                            : Qt.rgba(0, 0, 0, 0.2)
                        border.width: active ? 1 : 0
                        border.color: Qt.rgba(WallustColors.accent.r, WallustColors.accent.g, WallustColors.accent.b, 0.5)

                        Text {
                            id: tabLabel
                            anchors.centerIn: parent
                            text: modelData.label || "?"
                            color: modelData.ok ? WallustColors.moduleText : WallustColors.red
                            font.family: Style.fontFamily
                            font.pixelSize: Style.fontPixelSize - 1
                            font.bold: active
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: CodexBarService.selectIndex(index)
                        }
                    }
                }
            }
        }

        // Detail card
        Rectangle {
            width: parent.width
            visible: selected != null
            radius: 12
            color: Qt.rgba(0, 0, 0, 0.22)
            border.width: 1
            border.color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                WallustColors.borderColor.b, 0.4)
            implicitHeight: detailCol.implicitHeight + 20

            Column {
                id: detailCol
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 12
                spacing: 8

                RowLayout {
                    width: parent.width
                    Text {
                        text: selected ? selected.label : ""
                        color: WallustColors.sky
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 2
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        visible: selected && selected.plan && selected.plan.length
                        text: selected ? selected.plan : ""
                        color: WallustColors.mauve
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                    }
                }

                // Error state
                Text {
                    width: parent.width
                    visible: selected && !selected.ok
                    wrapMode: Text.WordWrap
                    text: selected ? selected.error : ""
                    color: WallustColors.red
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                }

                // OK usage
                Column {
                    width: parent.width
                    spacing: 6
                    visible: selected && selected.ok

                    Text {
                        text: (selected ? selected.windowLabel : "Credits") + ": "
                              + Math.round(selected ? selected.remainingPercent : 0) + "% left"
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 1
                        font.bold: true
                    }

                    // Progress track (remaining = filled from left in codexbar style)
                    Rectangle {
                        width: parent.width
                        height: 8
                        radius: 4
                        color: Qt.rgba(WallustColors.borderColor.r, WallustColors.borderColor.g,
                            WallustColors.borderColor.b, 0.35)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Math.max(0, Math.min(1,
                                (selected ? selected.remainingPercent : 0) / 100))
                            radius: 4
                            color: {
                                const rem = selected ? selected.remainingPercent : 0
                                if (rem < 15)
                                    return WallustColors.red
                                if (rem < 35)
                                    return WallustColors.yellow
                                return WallustColors.sky
                            }
                        }
                    }

                    Text {
                        text: selected ? (selected.resetLabel || "") : ""
                        color: WallustColors.moduleText
                        opacity: 0.7
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                    }

                    Text {
                        width: parent.width
                        visible: selected && selected.email && selected.email.length
                        elide: Text.ElideMiddle
                        text: selected ? selected.email : ""
                        color: WallustColors.moduleText
                        opacity: 0.5
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 1
                    }

                    Text {
                        visible: selected && selected.source && selected.source.length
                        text: "source: " + (selected ? selected.source : "")
                        color: WallustColors.moduleText
                        opacity: 0.4
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize - 2
                    }
                }
            }
        }

        Text {
            width: parent.width
            visible: providers.length > 0
            horizontalAlignment: Text.AlignHCenter
            text: "Tab · j/k · r refresh · Esc"
            color: WallustColors.moduleText
            opacity: 0.35
            font.family: Style.fontFamily
            font.pixelSize: 9
        }
    }
}
