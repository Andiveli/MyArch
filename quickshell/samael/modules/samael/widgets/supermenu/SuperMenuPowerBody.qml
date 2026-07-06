import QtQuick
import QtQuick.Controls
import qs
import qs.services
import qs.modules.samael

Column {
    id: root
    spacing: 6
    property int focusIndex: 0

    readonly property var actions: [
        { label: "Lock", run: () => Session.lock() },
        { label: "Suspend", run: () => Session.suspend() },
        { label: "Hibernate", run: () => Session.hibernate() },
        { label: "Logout", run: () => Session.logout() },
        { label: "Reboot", run: () => Session.reboot() },
        { label: "Shutdown", run: () => Session.poweroff() },
    ]

    function handleKey(event): bool {
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            focusIndex = Math.min(actions.length - 1, focusIndex + 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            focusIndex = Math.max(0, focusIndex - 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const a = actions[focusIndex]
            if (a) {
                a.run()
                GlobalStates.samaelSuperMenuOpen = false
            }
            event.accepted = true
            return true
        }
        return false
    }

    Repeater {
        model: root.actions
        delegate: Rectangle {
            required property int index
            required property var modelData
            width: parent.width
            height: 28
            color: root.focusIndex === index ? Qt.rgba(0.1, 0.45, 1, 0.2) : "transparent"
            border.width: root.focusIndex === index ? 1 : 0
            border.color: "#1a8cff"
            radius: 3
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                font.family: SamaelStyle.fontFamily
                font.pixelSize: 10
                color: SamaelStyle.textColor
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.focusIndex = index
                    modelData.run()
                    GlobalStates.samaelSuperMenuOpen = false
                }
            }
        }
    }
}