import qs.modules.common
import QtQuick

/**
 * Separator widget - Waybar style
 */
Item {
    id: root
    property string separatorType: "dot-line"  // dot, dot-line, line, blank, blank_2, blank_3
    property int implicitWidth: 8

    readonly property var separators: {
        "dot": "",
        "dot-line": "",
        "line": "|",
        "blank": "",
        "blank_2": "  ",
        "blank_3": "   "
    }

    MaterialSymbol {
        visible: root.separatorType !== "blank" && root.separatorType !== "blank_2" && root.separatorType !== "blank_3"
        anchors.centerIn: parent
        text: root.separators[root.separatorType] || " "
        iconSize: Appearance.font.pixelSize.small
        color: Appearance.colors.colOutlineVariant
    }
}
