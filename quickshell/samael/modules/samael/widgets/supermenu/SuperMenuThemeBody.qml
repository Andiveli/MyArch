import QtQuick
import QtQuick.Layouts
import Quickshell
import qs
import qs.modules.samael

Rectangle {
    id: root
    color: "transparent"
    implicitWidth: 480
    implicitHeight: 160

    property int focusIndex: 0
    readonly property var actions: [
        { label: "Open wallpaper picker", run: () => {
            GlobalStates.samaelSuperMenuOpen = false
            GlobalStates.wallpaperSelectorOpen = true
        }},
        { label: "Reload Wallust palette", run: () => WallustColors.reloadPaletteFromDisk() },
        { label: "Random wallpaper", run: () => {
            GlobalStates.samaelSuperMenuOpen = false
            Quickshell.execDetached(["bash", "-c",
                "d=\"$HOME/Pictures/wallpapers\"; mapfile -t a < <(find -L \"$d\" -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\)); [[ ${#a[@]} -gt 0 ]] && bash \"$HOME/.config/quickshell/samael/scripts/wallpaper/samael-wallpaper.sh\" \"${a[$RANDOM % ${#a[@]}]}\""
            ])
        }},
    ]

    function handleKey(event): bool {
        if (event.key === Qt.Key_J || event.key === Qt.Key_Down) {
            focusIndex = Math.min(actions.length - 1, focusIndex + 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_K || event.key === Qt.Key_Up) {
            focusIndex = Math.max(0, focusIndex - 1)
            event.accepted = true
            return true
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            const a = actions[focusIndex]
            if (a)
                a.run()
            event.accepted = true
            return true
        }
        return false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8
        Text {
            text: "THEME"
            font.family: SamaelStyle.fontFamily
            font.pixelSize: 11
            font.bold: true
            color: "#1a8cff"
        }
        Repeater {
            model: root.actions
            delegate: Rectangle {
                required property int index
                required property var modelData
                width: parent.width
                height: 28
                color: root.focusIndex === index ? Qt.rgba(0.1, 0.45, 1, 0.2) : "transparent"
                border.width: root.focusIndex === index ? 1 : 0
                border.color: "#1a8cff"
                radius: 3
                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.label
                    font.family: SamaelStyle.fontFamily
                    font.pixelSize: 10
                    color: "#e0e6f0"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        root.focusIndex = index
                        modelData.run()
                    }
                }
            }
        }
    }
}