import QtQuick
import "../singletons"

/** Fastfetch block — media surface typography (sky / buttonHover). */
Item {
    id: root

    readonly property real s: Math.max(0.85, Style.fontPixelSize / 11)

    implicitWidth: col.implicitWidth
    implicitHeight: col.implicitHeight

    Column {
        id: col
        width: parent.width
        spacing: 4 * s

        Text {
            width: parent.width
            text: LockService.sysLoading ? "Loading…" : (LockService.sysError || "")
            visible: text.length > 0
            color: WallustColors.red
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize - 1
        }

        Repeater {
            model: LockService.sysLines

            Row {
                required property var modelData
                width: col.width
                spacing: 0

                readonly property int colon: modelData.indexOf(": ")
                readonly property string k: colon >= 0 ? modelData.slice(0, colon) : modelData
                readonly property string v: colon >= 0 ? modelData.slice(colon + 2) : ""

                Text {
                    id: keyText
                    text: colon >= 0 ? k + ": " : k
                    color: WallustColors.sapphire
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    font.bold: true
                }
                Text {
                    width: Math.max(0, parent.width - keyText.width)
                    text: v
                    visible: v.length > 0
                    color: WallustColors.buttonHover
                    font.family: Style.fontFamily
                    font.pixelSize: Style.fontPixelSize
                    wrapMode: Text.Wrap
                }
            }
        }
    }
}