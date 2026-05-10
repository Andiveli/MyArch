import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Workspaces with Kanji icons - Waybar style
 * Uses Japanese numerals: 一, 二, 三, 四, 五, 六, 七, 八, 九, 十
 */
RowLayout {
    id: root
    spacing: 2

    readonly property color colActive: "#2600ff"  // Blue
    readonly property color colInactive: "#ff029e" // Pink/Magenta
    readonly property color colText: "#ffffff"

    readonly property var kanjiNumbers: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    // Get workspace by index (1-based)
    function getKanjiForWorkspace(wsId) {
        if (wsId >= 1 && wsId <= 10) {
            return root.kanjiNumbers[wsId - 1]
        }
        return wsId.toString()
    }

    // Current active workspace
    readonly property int activeWorkspace: HyprlandData.activeWorkspace?.id ?? 1

    // Generate workspace buttons for workspaces 1-5
    Repeater {
        model: 5

        delegate: Item {
            id: wsItem
            property int workspaceId: index + 1
            property bool isActive: root.activeWorkspace === workspaceId

            implicitWidth: kanjiText.implicitWidth + 8
            implicitHeight: Appearance.sizes.barHeight

            StyledText {
                id: kanjiText
                anchors.centerIn: parent
                text: root.getKanjiForWorkspace(wsItem.workspaceId)
                font.pixelSize: Appearance.font.pixelSize.normal
                font.weight: Font.Bold
                color: wsItem.isActive ? root.colActive : root.colInactive
            }

            TapHandler {
                onTapped: {
                    Hyprland.sendHyprlandEvent("workspace", wsItem.workspaceId)
                }
            }
        }
    }
}
