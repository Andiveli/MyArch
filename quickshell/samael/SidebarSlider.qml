import QtQuick

/**
 * Slider estilo ii/
 */
Rectangle {
    property real value: 0
    property real from: 0
    property real to: 1

    implicitWidth: 200
    implicitHeight: 8
    width: implicitWidth
    height: implicitHeight
    radius: 4
    color: "#252525"

    Rectangle {
        y: 0
        height: parent.height
        width: Math.max(0, Math.min(parent.width, parent.width * ((value - from) / (to - from))))
        color: "#cba6f7"
        radius: 4

        // Indicador
        Rectangle {
            x: parent.width - 8
            y: (parent.height - 14) / 2
            width: 8
            height: 14
            radius: 2
            color: "#cba6f7"
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            const ratio = mouse.x / parent.width
            value = from + ratio * (to - from)
        }
    }
}
