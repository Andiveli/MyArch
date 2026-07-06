import QtQuick
import Caelestia.Config
import qs.components
import qs.modules.common.widgets

Item {
    id: root

    /** 0–1 */
    property real fraction: 0
    property color fgColour: Colours.palette.m3primary
    property color bgColour: Colours.palette.m3secondaryContainer

    implicitHeight: 10
    implicitWidth: 120

    StyledProgressBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: 6
        from: 0
        to: 1
        value: root.fraction
        wavy: true
        animateWave: true
        waveFrequency: 5
        highlightColor: root.fgColour
        trackColor: root.bgColour
        valueBarHeight: 6
        valueBarWidth: width
    }
}