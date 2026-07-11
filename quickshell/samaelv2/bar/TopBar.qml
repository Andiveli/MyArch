import QtQuick
import "../singletons"

/**
 * Reserve strip: middle lives on overlay only; left/right pills are overlay-only too.
 */
Item {
    id: root

    property var barScreen: null

    readonly property int marginTop: ShellConfig.barMarginTop
    readonly property int marginBottom: ShellConfig.sectionBottomMargin

    readonly property int stripHeight: Style.barContentHeight + marginBottom + Style.barReserveSlop

    implicitHeight: marginTop + stripHeight
    implicitWidth: parent ? parent.width : 0
}