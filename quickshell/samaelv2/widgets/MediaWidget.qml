import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Mpris
import "../singletons"

Item {
    id: root
    readonly property int titleMax: ShellConfig.mediaBarTitleMaxWidth
    readonly property real glyphW: playGlyph.implicitWidth
    implicitWidth: glyphW + (titleBlockW > 0 ? rowLayout.spacing + titleBlockW : 0)
    implicitHeight: Math.max(rowLayout.implicitHeight, Style.barContentHeight)
    width: implicitWidth
    height: implicitHeight
    clip: true

    readonly property var activePlayer: MprisPlayers.activePlayer
    readonly property bool hasActiveMedia: activePlayer != null
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle)
    readonly property string lineText: {
        if (!hasActiveMedia)
            return ""
        const title = cleanedTitle.length ? cleanedTitle : qsTr("Unknown title")
        return title + (activePlayer.trackArtist ? " • " + activePlayer.trackArtist : "")
    }
    readonly property real titleBlockW: hasActiveMedia && lineText.length
            ? Math.min(titleText.implicitWidth + 1, titleMax)
            : 0

    Timer {
        running: ShellConfig.barEnabled && ShellConfig.hasWidgetAnywhere("media")
                && activePlayer?.playbackState === MprisPlaybackState.Playing
        interval: 500
        repeat: true
        onTriggered: if (activePlayer) activePlayer.positionChanged()
    }

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 4

        Text {
            id: playGlyph
            Layout.alignment: Qt.AlignVCenter
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
            color: WallustColors.moduleText
            text: activePlayer?.isPlaying ? "󰏦" : "󰎈"
        }

        Text {
            id: titleText
            visible: root.hasActiveMedia && root.lineText.length > 0
            Layout.preferredWidth: visible ? Math.min(implicitWidth + 1, root.titleMax) : 0
            Layout.maximumWidth: root.titleMax
            Layout.fillWidth: false
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            elide: Text.ElideRight
            wrapMode: Text.NoWrap
            font.family: Style.fontFamily
            font.pixelSize: Style.fontPixelSize
            color: WallustColors.moduleText
            text: root.lineText
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: event => {
            if (event.button === Qt.MiddleButton) {
                if (activePlayer)
                    activePlayer.togglePlaying()
                return
            }
            if (event.button === Qt.BackButton) {
                if (activePlayer)
                    activePlayer.previous()
                return
            }
            if (event.button === Qt.ForwardButton || event.button === Qt.RightButton) {
                if (activePlayer)
                    activePlayer.next()
                return
            }
            if (event.button === Qt.LeftButton && ShellActions.toggleMedia)
                ShellActions.toggleMedia()
        }
    }
}