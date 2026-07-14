pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications
import "../singletons"

Rectangle {
    id: root

    required property string appName
    required property var notifList
    required property real iconSize

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property var head: notifList.length ? notifList[0] : null
    readonly property bool critical: head?.urgency === NotificationUrgency.Critical

    property bool expanded: false
    readonly property int lineCount: expanded ? notifList.length : Math.min(3, notifList.length)

    radius: ShellConfig.cornerRadius
    color: critical
        ? Qt.rgba(WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.2)
        : Qt.rgba(WallustColors.buttonHover.r, WallustColors.buttonHover.g,
            WallustColors.buttonHover.b, 0.18)
    border.width: 1
    border.color: Qt.alpha(WallustColors.borderColor, 0.5)
    implicitHeight: bodyCol.implicitHeight + 24 * s
    height: implicitHeight

    RowLayout {
        id: bodyCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 12 * s
        spacing: 14 * s

        Rectangle {
            Layout.preferredWidth: iconSize
            Layout.preferredHeight: iconSize
            Layout.alignment: Qt.AlignTop
            radius: iconSize / 2
            color: critical
                ? Qt.rgba(WallustColors.red.r, WallustColors.red.g, WallustColors.red.b, 0.35)
                : Qt.rgba(WallustColors.sky.r, WallustColors.sky.g, WallustColors.sky.b, 0.28)

            Text {
                anchors.centerIn: parent
                text: "\uf0f3"
                color: critical ? WallustColors.red : WallustColors.sky
                font.family: Style.fontFamily
                font.pixelSize: Math.round(20 * s)
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8 * s

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * s

                Text {
                    Layout.fillWidth: true
                    text: appName
                    color: WallustColors.buttonHover
                    opacity: 0.88
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 1
                    elide: Text.ElideRight
                }

                Rectangle {
                    visible: notifList.length > 1
                    implicitWidth: countLbl.implicitWidth + 14 * s
                    implicitHeight: countLbl.implicitHeight + 6 * s
                    radius: height / 2
                    color: Qt.rgba(WallustColors.moduleBackground.r,
                        WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.65)

                    Text {
                        id: countLbl
                        anchors.centerIn: parent
                        text: String(notifList.length)
                        color: WallustColors.moduleText
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize
                        font.bold: true
                    }
                }
            }

            Repeater {
                model: lineCount

                ColumnLayout {
                    required property int index
                    Layout.fillWidth: true
                    spacing: 4 * s

                    readonly property var n: notifList[index]

                    Text {
                        Layout.fillWidth: true
                        visible: (n?.summary || "").length > 0
                        text: n?.summary || ""
                        color: critical ? WallustColors.red : WallustColors.sky
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 2
                        font.bold: true
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: (n?.body || "").length > 0
                        text: (n?.body || "").replace(/\n/g, " ")
                        color: WallustColors.moduleText
                        opacity: 0.78
                        font.family: Style.fontFamily
                        font.pixelSize: Style.fontPixelSize + 1
                        wrapMode: Text.Wrap
                        maximumLineCount: root.expanded ? 8 : 4
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        visible: index < lineCount - 1
                        color: WallustColors.borderColor
                        opacity: 0.3
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: notifList.length > 3 && !expanded
                text: "Show " + (notifList.length - 3) + " more…"
                color: WallustColors.sky
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize
                font.underline: true

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expanded = true
                }
            }
        }
    }
}