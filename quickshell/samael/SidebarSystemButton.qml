import QtQuick

/**
 * System Button estilo ii/
 */
Item {
    property string icon
    property string text
    property color color
    signal clicked()

    width: 95
    height: 44

    Rectangle {
        anchors.fill: parent
        color: "#1a1a1a"
        radius: 10
        border.width: 1
        border.color: "#f700ff"
    }

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            text: icon
            font.pixelSize: 16
            color: color
        }

        Text {
            text: text
            font.pixelSize: 12
            font.bold: true
            color: color
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: clicked()
    }
}
