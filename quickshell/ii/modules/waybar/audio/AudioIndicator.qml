import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts

/**
 * Audio indicator with volume and microphone - Waybar style
 */
RowLayout {
    id: root
    spacing: 2

    readonly property color colAudio: "#ff00bf"  // Magenta/Rosa
    readonly property color colMic: "#89dceb"    // Sky blue
    readonly property color colText: "#e5d9f5"

    // Volume icon
    MaterialSymbol {
        id: volumeIcon
        text: {
            const vol = Audio.sink?.audio?.volume ?? 0
            if (Audio.sink?.audio?.muted ?? false) return "volume_off"
            if (vol < 0.25) return "volume_mute"
            if (vol < 0.5) return "volume_down"
            return "volume_up"
        }
        iconSize: Appearance.font.pixelSize.normal
        color: root.colAudio
    }

    // Volume percentage
    StyledText {
        text: `${Math.round((Audio.sink?.audio?.volume ?? 0) * 100)}%`
        font.pixelSize: Appearance.font.pixelSize.smaller
        color: root.colText
    }

    // Separator
    Rectangle {
        width: 1
        height: 14
        color: Appearance.colors.colOutlineVariant
        opacity: 0.5
        Layout.leftMargin: 4
        Layout.rightMargin: 4
    }

    // Microphone
    RowLayout {
        spacing: 2

        MaterialSymbol {
            text: Audio.source?.audio?.muted ?? false ? "mic_off" : "mic"
            iconSize: Appearance.font.pixelSize.small
            color: root.colMic
        }

        StyledText {
            text: `${Math.round((Audio.source?.audio?.volume ?? 0) * 100)}%`
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: root.colText
            visible: !(Audio.source?.audio?.muted ?? false)
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton
        onTapped: {
            Audio.toggleMute()
        }
    }

    TapHandler {
        acceptedButtons: Qt.RightButton
        onTapped: {
            // Open pavucontrol
            Quickshell.execDetached(["pavucontrol", "-t", "3"])
        }
    }
}
