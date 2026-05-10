import QtQuick

/**
 * Info Box estilo ii/
 */
Column {
    property string label
    property string value
    property color color

    width: 90
    height: 55

    Rectangle {
        width: parent.width
        height: parent.height
        color: "#1a1a1a"
        radius: 10
        border.width: 1
        border.color: "#f700ff"

        Column {
            anchors.centerIn: parent
            spacing: 3

            Text {
                text: label
                font.pixelSize: 11
                color: "#686868"
                anchors.horizontalCenter: parent.horizontalCenter
                font.bold: true
            }

            Text {
                text: value
                font.pixelSize: 16
                font.bold: true
                color: color
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}
