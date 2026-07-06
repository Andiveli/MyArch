import QtQuick
import QtQuick.Layouts
import qs
import qs.services
import qs.modules.samael

Rectangle {
    id: root
    required property var notif
    property int toastWidth: 320

    width: toastWidth
    radius: 10
    color: WallustColors.moduleBackground
    border.width: 2
    border.color: WallustColors.borderColor
    implicitHeight: content.implicitHeight + 16

    opacity: 0
    transform: Translate { y: -12 }

    Component.onCompleted: enterAnim.start()

    ParallelAnimation {
        id: enterAnim
        NumberAnimation { target: root; property: "opacity"; from: 0; to: 1; duration: 180; easing.type: Easing.OutCubic }
        NumberAnimation { target: root.transform[0]; property: "y"; from: -12; to: 0; duration: 220; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }

    function dismissAnimated() {
        exitAnim.start()
    }

    SequentialAnimation {
        id: exitAnim
        ParallelAnimation {
            NumberAnimation { target: root; property: "opacity"; to: 0; duration: 140 }
            NumberAnimation { target: root.transform[0]; property: "x"; to: toastWidth * 0.35; duration: 160; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                if (notif)
                    Notifications.discardNotification(notif.notificationId)
            }
        }
    }

    ColumnLayout {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: (notif?.appName || "?") + (notif?.summary ? " · " + notif.summary : "")
            elide: Text.ElideRight
            color: WallustColors.moduleText
            font.family: SamaelStyle.fontFamily
            font.pixelSize: SamaelStyle.fontPixelSize
        }
        Text {
            Layout.fillWidth: true
            visible: (notif?.body || "").length > 0
            text: notif.body || ""
            elide: Text.ElideRight
            maximumLineCount: 3
            wrapMode: Text.Wrap
            color: WallustColors.sapphire
            font.family: SamaelStyle.fontFamily
            font.pixelSize: Math.max(8, SamaelStyle.fontPixelSize - 1)
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.dismissAnimated()
    }
}