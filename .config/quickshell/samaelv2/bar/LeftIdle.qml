import QtQuick
import "../singletons"
import "./BarSection.qml"
import "./WidgetHost.qml"

/** Rest-state left (workspaces capsule); morph on overlay only. */
BarSection {
    id: leftIdleRoot
    chromeless: true
    bottomMargin: ShellConfig.sectionBottomMargin
    innerMarginLeft: ShellConfig.innerMarginLeftAll
    innerMarginRight: ShellConfig.innerMarginLeftAll
    innerMarginTop: ShellConfig.innerMarginLeftAll
    innerMarginBottom: ShellConfig.innerMarginLeftAll
    property var barScreen: null
    WidgetHost {
        zone: "left"
        widgetIds: ShellConfig.barLeft
        barScreen: leftIdleRoot.barScreen
    }
}