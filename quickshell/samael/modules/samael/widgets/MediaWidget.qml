import QtQuick
import qs
import qs.modules.samael
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.common.functions
import qs.services

Item {
    id: root
    implicitWidth: rowLayout.implicitWidth + SamaelStyle.modulePaddingH * 2
    implicitHeight: Math.max(rowLayout.implicitHeight, 20)

    readonly property MprisPlayer activePlayer: MprisController.activePlayer
    readonly property string cleanedTitle: StringUtils.cleanMusicTitle(activePlayer?.trackTitle) || "No media"

    Timer {
        running: GlobalStates.barOpen && activePlayer?.playbackState === MprisPlaybackState.Playing
        interval: Math.max(1500, Config?.options?.resources?.updateInterval ?? 3000)
        repeat: true
        onTriggered: if (activePlayer) activePlayer.positionChanged()
    }

    RowLayout {
        id: rowLayout
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        Text {
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: SamaelStyle.fontPixelSize
            color: WallustColors.moduleText
            text: activePlayer?.isPlaying ? "󰏦" : "󰎈"
        }

        Text {
            Layout.maximumWidth: 140
            elide: Text.ElideRight
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: SamaelStyle.fontPixelSize
            color: WallustColors.moduleText
            text: cleanedTitle + (activePlayer?.trackArtist ? " • " + activePlayer.trackArtist : "")
        }
    }

    function barContentItem() {
        let p = root.parent
        while (p) {
            if (p.barScreenName !== undefined)
                return p
            p = p.parent
        }
        return null
    }

        function publishMediaAnchor() {
            if (GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing)
                return
            const bar = barContentItem()
            if (!bar || !bar.barScreenName?.length || root.width <= 0)
                return
            const cx = root.mapToItem(bar, root.width / 2, 0)
            GlobalStates.samaelMediaScreenName = bar.barScreenName
            GlobalStates.samaelMediaCenterX = bar.barMarginLeft + cx.x
        }

        onWidthChanged: publishMediaAnchor()
        Component.onCompleted: publishMediaAnchor()

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton | Qt.BackButton | Qt.ForwardButton | Qt.RightButton | Qt.LeftButton
        onPressed: (event) => {
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
                if (event.button === Qt.LeftButton) {
                    const bar = barContentItem()
                    if (bar?.publishMediaDockAnchor)
                        bar.publishMediaDockAnchor()
                    publishMediaAnchor()
                    const willOpen = !GlobalStates.mediaControlsOpen
                    if (willOpen) {
                        if (typeof SamaelBarNavHub !== "undefined" && SamaelBarNavHub.saveCurrentHyprClient)
                            SamaelBarNavHub.saveCurrentHyprClient()
                    }
                    GlobalStates.mediaControlsOpen = willOpen
                    if (!willOpen) {
                        Qt.callLater(() => {
                            if (typeof SamaelBarNavHub !== "undefined" && SamaelBarNavHub.restoreHyprClientIfNeeded)
                                SamaelBarNavHub.restoreHyprClientIfNeeded()
                        })
                    }
                }
        }
    }
}
