import QtQuick
import qs.modules.samael

Item {
    id: root
    property string variant: "dot-line"

    implicitWidth: label.implicitWidth + SamaelStyle.modulePaddingH * 2
    implicitHeight: SamaelStyle.barContentHeight

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        anchors.horizontalCenter: parent.horizontalCenter
        text: variant === "dot-line" ? "" : variant === "line" ? "|" : ""
        color: WallustColors.moduleText
        font.family: SamaelStyle.fontFamily
        font.bold: SamaelStyle.fontBold
        font.pixelSize: SamaelStyle.fontPixelSize
        verticalAlignment: Text.AlignVCenter
    }
}