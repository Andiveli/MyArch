import QtQuick
import qs.modules.samael

// Waybar per-module padding-left/right: 6px
Item {
    id: root
    property alias text: label.text
    property color textColor: WallustColors.moduleText
    property int padH: SamaelStyle.modulePaddingH

    implicitWidth: label.implicitWidth + padH * 2
    implicitHeight: label.implicitHeight

    Text {
        id: label
        anchors.centerIn: parent
        font.family: SamaelStyle.fontFamily
        font.pixelSize: SamaelStyle.fontPixelSize
        font.bold: SamaelStyle.fontBold
        color: root.textColor
    }
}