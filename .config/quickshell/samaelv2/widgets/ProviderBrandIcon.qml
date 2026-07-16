import QtQuick
import "../singletons"

/** CodexBar upstream art — use PNG (Qt Image often fails on local SVG). */
Item {
    id: root
    property string providerId: ""
    property bool onAccent: false
    property real iconSize: 22

    implicitWidth: iconSize
    implicitHeight: iconSize

    readonly property string _id: providerId ? String(providerId) : ""

    readonly property url assetUrl: _id.length
        ? Qt.resolvedUrl("../assets/codexbar/ProviderIcon-" + _id + ".png")
        : ""

    Image {
        id: brandImg
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize
        source: root.assetUrl
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        visible: status === Image.Ready && source !== ""
    }

    Text {
        anchors.centerIn: parent
        visible: !brandImg.visible
        text: "?"
        color: root.onAccent ? WallustColors.moduleBackground : WallustColors.moduleText
        font.family: Style.fontFamily
        font.pixelSize: root.iconSize * 0.5
        font.bold: true
    }
}