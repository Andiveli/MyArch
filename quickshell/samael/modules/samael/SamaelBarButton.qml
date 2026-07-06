import QtQuick
import qs.modules.samael

Item {
    id: root
    property alias text: label.text
    property color normalColor: WallustColors.moduleText
    property color hoverColor: WallustColors.buttonHover
    property int hitPaddingH: SamaelStyle.modulePaddingH
    property int hitPaddingV: 0
    signal clicked(var mouse)

    implicitWidth: label.implicitWidth + hitPaddingH * 2
    implicitHeight: label.implicitHeight + hitPaddingV * 2

    Text {
        id: label
        anchors.centerIn: parent
        font.family: SamaelStyle.fontFamily
        font.pixelSize: SamaelStyle.fontPixelSize
        font.bold: SamaelStyle.fontBold
        color: hoverMa.containsMouse ? root.hoverColor : root.normalColor
    }

    MouseArea {
        id: hoverMa
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: (mouse) => root.clicked(mouse)
    }
}