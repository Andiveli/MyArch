pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.services
import qs.modules.samael

/** Lock sidebar: fastfetch pokemon config (replaces caelestiafetch). */
StyledRect {
    id: root

    required property int rootHeight

    implicitHeight: Math.max(layout.implicitHeight + layout.anchors.margins * 2, ffText.implicitHeight + Tokens.padding.extraLarge * 2)
    radius: Tokens.rounding.medium
    color: Colours.tPalette.m3surfaceContainer

    ColumnLayout {
        id: layout

        anchors.fill: parent
        anchors.margins: Tokens.padding.extraLarge
        spacing: Tokens.spacing.small

        StyledText {
            Layout.fillWidth: true
            text: SamaelFastfetch.loading ? qsTr("Loading…") : (SamaelFastfetch.lastError && !SamaelFastfetch.text.length ? SamaelFastfetch.lastError : "")
            visible: text.length > 0
            color: WallustColors.foreground
            font: Tokens.font.body.small
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
        }

        Text {
            id: ffText

            Layout.fillWidth: true
            Layout.preferredWidth: parent.width - layout.anchors.margins * 2
            text: SamaelFastfetch.text
            visible: SamaelFastfetch.text.length > 0
            color: WallustColors.foreground
            font.family: Tokens.font.mono.family
            font.pixelSize: root.width > Tokens.sizes.lock.largeFontWidth
                              ? Tokens.font.mono.medium.pointSize
                              : Tokens.font.mono.small.pointSize
            lineHeight: 1.15
            lineHeightMode: Text.ProportionalHeight
            wrapMode: Text.NoWrap
            renderType: Text.NativeRendering
            textFormat: Text.PlainText
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideNone
        }
    }

    Component.onCompleted: SamaelFastfetch.reload()
}