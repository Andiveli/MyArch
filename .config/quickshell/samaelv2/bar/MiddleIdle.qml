import QtQuick
import "../singletons"
import "./BarSection.qml"
import "./WidgetHost.qml"

/** Rest-state middle (fixed size); morph happens on overlay layer only. */
BarSection {
    compact: true
    bottomMargin: ShellConfig.sectionBottomMargin
    innerMarginLeft: ShellConfig.innerMarginMiddleSides
    innerMarginRight: ShellConfig.innerMarginMiddleSides
    WidgetHost {
        zone: "middle"
        widgetIds: ShellConfig.barMiddle
        spacing: 6
    }
}