import QtQuick
import "../singletons"

/** Shown when Caelestia.Services is not installed (no AUR caelestia-shell). */
Item {
    implicitWidth: ShellConfig.lyricsPanelWidth
    implicitHeight: 220

    Text {
        anchors.centerIn: parent
        width: parent.width - 12
        wrapMode: Text.Wrap
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("Lyrics need the Caelestia plugin:\nyay -S caelestia-shell")
        font.family: Style.fontFamily
        font.pixelSize: Style.fontPixelSize - 1
        color: WallustColors.buttonHover
    }
}