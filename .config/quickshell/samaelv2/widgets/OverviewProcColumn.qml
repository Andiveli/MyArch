pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../singletons"

/** One overview-style card: header + up to 3 process rows with smooth bars. */
Rectangle {
    id: root

    property string glyph: "\uf2db"
    property string title: ""
    property color accentColor: WallustColors.sky
    property color barMuted: accentColor
    property var rows: []
    property string metricKey: "cpuPct"
    property int columnIndex: 0
    property bool active: false
    property int selectedRow: -1

    readonly property int rowH: 42
    readonly property int headerBlockH: 40

    implicitHeight: headerBlockH + rowH * 3 + 8 * 2 + 6 * 4

    radius: 10
    color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
        WallustColors.moduleBackground.b, 0.55)
    border.width: active ? 1 : 0
    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.4)

    Behavior on border.width {
        NumberAnimation { duration: Motion.fast }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                text: glyph
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 1
                color: root.accentColor
                opacity: active ? 1 : 0.65
            }

            ColumnLayout {
                spacing: 0
                Text {
                    text: title
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    font.bold: true
                    color: active ? root.accentColor : WallustColors.moduleText
                }
                Text {
                    visible: active && root.selectedRow >= 0 && root.selectedRow < root.rows.length
                    text: root.rows[root.selectedRow]?.name ?? ""
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 2
                    color: WallustColors.buttonHover
                    opacity: 0.75
                    elide: Text.ElideRight
                    Layout.maximumWidth: root.width - 40
                }
            }

            Item { Layout.fillWidth: true }

            Text {
                visible: root.rows.length > 0 && root.selectedRow >= 0 && root.selectedRow < root.rows.length
                text: {
                    const r = root.rows[root.selectedRow]
                    if (!r)
                        return ""
                    const v = metricKey === "cpuPct" ? r.cpuPct : r.memPct
                    return v.toFixed(1) + "%"
                }
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize + 1
                font.bold: true
                color: root.accentColor
            }
        }

        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                readonly property var rowData: index < root.rows.length ? root.rows[index] : null
                readonly property real metricVal: rowData
                    ? (root.metricKey === "cpuPct" ? rowData.cpuPct : rowData.memPct) : 0
                readonly property bool rowFocused: root.selectedRow === index
                readonly property bool isTop: index === 0 && rowData

                Layout.fillWidth: true
                Layout.preferredHeight: root.rowH
                radius: 10
                color: rowFocused
                    ? Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
                    : Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                        WallustColors.moduleBackground.b, 0.35)
                border.width: rowFocused ? 1 : 0
                border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)

                Behavior on color {
                    ColorAnimation { duration: Motion.standard; easing.type: Easing.OutCubic }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    anchors.topMargin: 5
                    anchors.bottomMargin: 5
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.preferredWidth: 12
                            text: String(index + 1)
                            font.family: Style.fontFamily
                            font.pixelSize: 8
                            color: WallustColors.buttonHover
                            opacity: 0.6
                        }

                        Text {
                            Layout.fillWidth: true
                            text: rowData ? rowData.name : "—"
                            font.family: Style.fontFamily
                            font.pixelSize: rowFocused ? Style.fontPixelSize : Style.fontPixelSize - 1
                            font.bold: rowFocused || isTop
                            color: rowFocused ? root.accentColor : WallustColors.moduleText
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: !!rowData
                            text: metricVal.toFixed(1) + "%"
                            font.family: Style.fontFamily
                            font.pixelSize: 9
                            color: rowFocused ? root.accentColor : WallustColors.buttonHover
                            opacity: rowFocused ? 1 : 0.85
                        }
                    }

                    OverviewTrafficBar {
                        Layout.fillWidth: true
                        implicitHeight: 6
                        barRadius: 3
                        fraction: Math.min(1, metricVal / 100)
                        trackOpacity: 0.12
                    }
                }
            }
        }
    }
}