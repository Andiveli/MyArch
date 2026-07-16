import QtQuick
import QtQuick.Layouts
import "../singletons"

/** Mic / system volume line for record surface (h/l when focused). */
Item {
    id: root

    property bool vimFocus: false
    property bool focusMute: false
    property bool focusVol: false
    property string label: ""
    property string icon: ""
    property int volume: 0
    property bool muted: false
    /** Callable mute toggle — do not name onMute (reserved handler prefix in QML). */
    property var muteAction: null

    implicitHeight: column.implicitHeight
    implicitWidth: 160

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 8
                color: Qt.rgba(0, 0, 0, 0.2)
                border.width: root.focusMute && root.vimFocus ? 2 : 1
                border.color: root.focusMute && root.vimFocus ? WallustColors.sky : WallustColors.borderColor

                Text {
                    anchors.centerIn: parent
                    text: root.icon
                    color: root.muted ? WallustColors.moduleText : WallustColors.accent
                    opacity: root.muted ? 0.45 : 1
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.muteAction)
                            root.muteAction()
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.label
                color: WallustColors.moduleText
                font.family: Style.fontFamily
                font.pixelSize: Style.fontPixelSize - 1
                font.bold: root.focusMute && root.vimFocus
            }

            Text {
                text: root.muted ? "mute" : (root.volume + "%")
                color: WallustColors.accent
                font.family: Style.fontFamily
                font.pixelSize: 9
                opacity: root.focusVol && root.vimFocus ? 1 : 0.7
            }
        }

        Rectangle {
            id: volTrack
            Layout.fillWidth: true
            Layout.preferredHeight: 10
            radius: 5
            color: Qt.rgba(0, 0, 0, 0.12)
            border.width: root.focusVol && root.vimFocus ? 2 : 0
            border.color: WallustColors.sky

            readonly property real frac: root.muted ? 0 : Math.max(0, Math.min(1, root.volume / 100))

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 3
                color: Qt.rgba(WallustColors.moduleText.r, WallustColors.moduleText.g,
                    WallustColors.moduleText.b, 0.12)
            }
            Rectangle {
                height: volTrack.height - 4
                width: Math.max(0, (volTrack.width - 4) * volTrack.frac)
                anchors.left: volTrack.left
                anchors.leftMargin: 2
                anchors.verticalCenter: volTrack.verticalCenter
                radius: 3
                color: WallustColors.accent
            }
        }
    }
}