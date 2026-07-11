import QtQuick
import "../singletons"
import "."

Item {
    implicitWidth: glyph.implicitWidth
    implicitHeight: Style.barContentHeight

    readonly property var activeNet: WifiSurfaceLogic.activeNet
    readonly property bool wifiOn: WifiSurfaceLogic.wifiOn
    readonly property int signalLevel: activeNet ? (activeNet.signalStrength || 0) : 0

    WifiSignalGlyph {
        id: glyph
        anchors.verticalCenter: parent.verticalCenter
        width: Style.fontPixelSize + 2
        height: Style.fontPixelSize + 2
        level: wifiOn ? signalLevel : 0
        radioOn: wifiOn
        strokeColor: wifiOn ? (activeNet ? WallustColors.accent : WallustColors.moduleText) : WallustColors.moduleText
        opacity: wifiOn ? 1 : 0.45
    }

    MouseArea {
        anchors.fill: parent
        onClicked: ShellActions.toggleWifi?.()
    }
}