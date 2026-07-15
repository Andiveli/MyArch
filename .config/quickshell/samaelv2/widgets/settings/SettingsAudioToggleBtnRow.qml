import QtQuick
import "../../singletons"

/** Mute / play — click, Space, or l/Enter when focused. */
SettingsConnectedRow {
    id: root

    readonly property bool settingsFocusable: true
    property string label: ""
    property bool enabled: true
    signal activated()

    function trigger() {
        if (enabled)
            root.activated()
    }

    implicitHeight: 40
    opacity: enabled ? 1 : 0.4

    MouseArea {
        z: 2
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onClicked: root.trigger()
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: root.vimFocus ? WallustColors.accent : WallustColors.moduleText
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize - 1
        font.bold: root.vimFocus
    }
}