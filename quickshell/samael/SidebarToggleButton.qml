import QtQuick

/**
 * Toggle Button estilo ii/
 */
Item {
    property string icon
    property bool active
    property color activeColor
    signal clicked()

    width: 50
    height: 50

    // Fondo con gradiente sutil
    Rectangle {
        anchors.fill: parent
        color: active ? activeColor : "#1a1a1a"
        radius: 12
        border.width: 2
        border.color: active ? activeColor : "#f700ff"
    }

    // Glow effect cuando está activo
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 12
        border.width: 2
        border.color: activeColor
        opacity: active ? 0.3 : 0
    }

    Text {
        anchors.centerIn: parent
        text: icon
        font.pixelSize: 22
        color: active ? "#000000" : activeColor
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: clicked()
    }
}
