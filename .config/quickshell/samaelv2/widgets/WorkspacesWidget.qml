import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../singletons"

// Waybar hyprland/workspaces#kanji — persistent 5, 六…十 when needed (max 10)
Item {
    id: root

    /** Set from bar (monitor this PanelWindow is on). */
    property var barScreen: null

    readonly property int persistentCount: 5
    readonly property int maxWorkspace: 10
    readonly property int cellWidth: 22
    readonly property int activePillWidth: 26
    /** Air around kanji track inside left pill (not pill padH). */
    readonly property int capsulePadH: 10
    readonly property int capsulePadV: 4

    readonly property HyprlandMonitor monitor: barScreen ? Hyprland.monitorFor(barScreen) : Hyprland.focusedMonitor
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? 1

    readonly property int workspaceCount: {
        let high = persistentCount
        const aid = activeWsId
        if (aid > high)
            high = aid
        const values = Hyprland.workspaces ? Hyprland.workspaces.values : []
        for (let i = 0; i < values.length; i++) {
            const id = values[i].id
            if (id > high)
                high = id
        }
        return Math.min(Math.max(persistentCount, high), maxWorkspace)
    }

    readonly property int activeCellIndex: {
        const idx = activeWsId - 1
        if (idx < 0)
            return 0
        if (idx >= workspaceCount)
            return Math.max(0, workspaceCount - 1)
        return idx
    }

    readonly property int trackWidth: workspaceCount * cellWidth
    readonly property real activePillX: activeCellIndex * cellWidth + (cellWidth - activePillWidth) / 2
    readonly property list<string> kanjiLabels: ["一", "二", "三", "四", "五", "六", "七", "八", "九", "十"]

    readonly property int baseCapsuleWidth: trackWidth + capsulePadH
    readonly property int baseCapsuleHeight: 18 + capsulePadV * 2
    property real widthWobble: 0

    readonly property int wobbleReserve: 8
    implicitWidth: baseCapsuleWidth + wobbleReserve
    implicitHeight: baseCapsuleHeight
    width: implicitWidth
    height: implicitHeight

        onActiveWsIdChanged: widthWobbleAnim.restart()

        FontLoader {
            id: kanjiFontLoader
        source: "file:///usr/share/fonts/droid/DroidSansFallback.ttf"
    }

    SequentialAnimation {
        id: widthWobbleAnim
        NumberAnimation {
            target: root
            property: "widthWobble"
            from: widthWobble
            to: 8
            duration: 120
            easing.type: Easing.OutBack
            easing.overshoot: 1.682
        }
        NumberAnimation {
            target: root
            property: "widthWobble"
            to: 0
            duration: 300
            easing.type: Easing.OutBack
            easing.overshoot: 1.682
        }
    }

    Item {
        id: wsCapsule
        anchors.centerIn: parent
        width: root.baseCapsuleWidth + root.widthWobble
        height: root.baseCapsuleHeight

        Rectangle {
            anchors.fill: parent
            radius: 15
            border.width: 2
            border.color: WallustColors.borderColor
            color: "transparent"
            opacity: 0.8
        }

        Item {
            id: kanjiTrack
            anchors.centerIn: parent
            width: root.trackWidth
            height: 18
            clip: true

            Rectangle {
                id: activePill
                z: 0
                height: 18
                width: root.activePillWidth
                radius: 12
                color: "#000000"
                x: root.activePillX
                y: 0

                Behavior on x {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.682
                    }
                }
            }

            Row {
                id: kanjiRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Repeater {
                    model: root.workspaceCount

                    Item {
                        id: wsCell
                        required property int index
                        readonly property int wsId: index + 1

                        width: root.cellWidth
                        height: 18

                        readonly property bool isActive: root.activeWsId === wsId
                        readonly property bool isUrgent: {
                            const vals = Hyprland.workspaces ? Hyprland.workspaces.values : []
                            for (let i = 0; i < vals.length; i++) {
                                if (vals[i].id === wsId && vals[i].urgent)
                                    return true
                            }
                            return false
                        }

                        Text {
                            anchors.centerIn: parent
                            text: wsId >= 1 && wsId <= 10 ? root.kanjiLabels[wsId - 1] : String(wsId)
                            color: wsCell.isActive ? WallustColors.workspaceActive
                                  : wsCell.isUrgent ? WallustColors.workspaceUrgent
                                  : WallustColors.workspaceInactive
                            font.pixelSize: Style.fontPixelSize
                            font.bold: Style.fontBold
                            font.family: kanjiFontLoader.status === FontLoader.Ready
                                         ? kanjiFontLoader.name
                                         : "Sans Serif"
                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.682
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}