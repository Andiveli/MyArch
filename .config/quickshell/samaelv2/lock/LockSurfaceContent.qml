import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../singletons"
import "./LockSysInfo.qml"
import "./LockMediaPanel.qml"
import "./LockNotifPanel.qml"
import "./LockClock.qml"
import "./LockPasswordField.qml"

FocusScope {
    id: root

    required property var pamHost
    required property real contentScale

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)
    readonly property real pad: ShellConfig.sectionPadH
    readonly property real colGap: 14 * s
    readonly property var loc: Qt.locale()

    readonly property real probeLeftH: sysInfoProbe.implicitHeight + 10 * s + 1 + 10 * s + mediaProbe.implicitHeight

    /** Solo fastfetch + media — define altura de card y líneas */
    readonly property real leftStackH: {
        if (LockService.layoutFrozen && LockService.layoutLeftColH > 24)
            return LockService.layoutLeftColH
        const live = leftCol.implicitHeight
        if (live > 24)
            return live
        if (probeLeftH > 24)
            return probeLeftH
        if (LockService.layoutLeftColH > 24)
            return LockService.layoutLeftColH
        return probeLeftH
    }

    readonly property real cardRowH: leftStackH

    function publishLeftHeight() {
        const h = leftCol.implicitHeight > 24 ? leftCol.implicitHeight : probeLeftH
        if (h > 24)
            LockService.layoutLeftColH = h
    }

    anchors.fill: parent
    focus: true
    activeFocusOnTab: false

    Keys.onPressed: event => {
        if (!pamHost)
            return
        if (pamHost.unlocking)
            return
        pamHost.handleKey(event)
        if (event.accepted)
            event.accepted = true
    }

    Component.onCompleted: {
        Qt.callLater(forceActiveFocus)
        Qt.callLater(publishLeftHeight)
    }

    Connections {
        target: LockService
        function onSysRevisionChanged() {
            Qt.callLater(root.publishLeftHeight)
        }
    }

    Connections {
        target: leftCol
        function onImplicitHeightChanged() {
            if (!LockService.layoutFrozen)
                Qt.callLater(root.publishLeftHeight)
        }
    }

    LockSysInfo {
        id: sysInfoProbe
        visible: false
        width: 280 * s
    }

    LockMediaPanel {
        id: mediaProbe
        visible: false
        width: 280 * s
    }

    RowLayout {
        id: columns
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: pad
        spacing: colGap
        height: cardRowH
        implicitHeight: cardRowH

        Item {
            Layout.preferredWidth: 1
            Layout.minimumWidth: 168 * s
            Layout.fillWidth: true
            Layout.preferredHeight: cardRowH
            Layout.maximumHeight: cardRowH
            Layout.alignment: Qt.AlignTop

            Column {
                id: leftCol
                width: parent.width
                spacing: 10 * s

                LockSysInfo {
                    width: parent.width
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: WallustColors.borderColor
                    opacity: 0.35
                }

                LockMediaPanel {
                    width: parent.width
                }
            }
        }

        Rectangle {
            Layout.preferredHeight: cardRowH
            Layout.preferredWidth: 1
            Layout.maximumWidth: 1
            color: WallustColors.borderColor
            opacity: 0.35
        }

        Item {
            Layout.preferredWidth: 1.12
            Layout.minimumWidth: 220 * s
            Layout.fillWidth: true
            Layout.preferredHeight: cardRowH
            Layout.maximumHeight: cardRowH
            Layout.alignment: Qt.AlignTop
            clip: true

            ColumnLayout {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14 * s

                LockClock {
                    Layout.alignment: Qt.AlignHCenter
                    contentScale: root.contentScale
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: loc.toString(new Date(), "dddd • d MMM").toUpperCase()
                    color: WallustColors.moduleText
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize + 2
                    font.bold: true
                    font.letterSpacing: 0.6 * s
                }

                LockPasswordField {
                    Layout.alignment: Qt.AlignHCenter
                    pamHost: root.pamHost
                    contentScale: root.contentScale
                    maxWidth: Math.min(320 * contentScale, parent.width - 8)
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    visible: pamHost.statusText.length > 0 && pamHost.buffer.length > 0
                    text: pamHost.statusText
                    color: WallustColors.red
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize - 1
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Rectangle {
            Layout.preferredHeight: cardRowH
            Layout.preferredWidth: 1
            Layout.maximumWidth: 1
            color: WallustColors.borderColor
            opacity: 0.35
        }

        Item {
            Layout.preferredWidth: 1
            Layout.minimumWidth: 168 * s
            Layout.fillWidth: true
            Layout.preferredHeight: cardRowH
            Layout.maximumHeight: cardRowH
            Layout.alignment: Qt.AlignTop

            Rectangle {
                anchors.fill: parent
                radius: ShellConfig.cornerRadius * 0.85
                color: Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g,
                    WallustColors.moduleBackground.b, 0.55)
                clip: true

                LockNotifPanel {
                    anchors.fill: parent
                    anchors.margins: 10 * s
                }
            }
        }
    }
}