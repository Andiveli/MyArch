import QtQuick
import QtQuick.Layouts
import "../singletons"

/**
 * Bar zone chrome. innerMargin* = space between border and widgets (not screen margin).
 * -1 on a side → use compact/default module inset from ShellConfig.
 */
Rectangle {
    id: root

    default property alias content: innerLayout.data

    property int chromeRadius: ShellConfig.cornerRadius
    property int bottomMargin: ShellConfig.sectionBottomMargin
    property bool chromeless: false
    property bool compact: false

    property int innerMarginLeft: -1
    property int innerMarginRight: -1
    property int innerMarginTop: -1
    property int innerMarginBottom: -1

    readonly property int defaultH: chromeless ? 0 : (compact ? ShellConfig.sectionPadHCompact : ShellConfig.sectionPadH)
    readonly property int defaultTop: chromeless ? 0 : (compact ? ShellConfig.sectionPadTopCompact : ShellConfig.sectionPadTop)
    readonly property int defaultBottom: chromeless ? 0 : (compact ? ShellConfig.sectionPadBottomCompact : ShellConfig.sectionPadBottom)

    readonly property int insetL: innerMarginLeft >= 0 ? innerMarginLeft : defaultH
    readonly property int insetR: innerMarginRight >= 0 ? innerMarginRight : defaultH
    readonly property int insetT: innerMarginTop >= 0 ? innerMarginTop : defaultTop
    readonly property int insetB: innerMarginBottom >= 0 ? innerMarginBottom : defaultBottom

    color: chromeless ? "transparent" : Qt.rgba(WallustColors.moduleBackground.r, WallustColors.moduleBackground.g, WallustColors.moduleBackground.b, 0.92)
    radius: chromeRadius
    border.width: chromeless ? 0 : 2
    border.color: WallustColors.borderColor

    implicitWidth: innerLayout.implicitWidth + insetL + insetR
    implicitHeight: innerLayout.implicitHeight + insetT + insetB + bottomMargin
    clip: true

    RowLayout {
        id: innerLayout
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            leftMargin: root.insetL
            rightMargin: root.insetR
            topMargin: root.insetT
            bottomMargin: root.insetB + root.bottomMargin
        }
        spacing: compact ? 6 : 8
    }
}
