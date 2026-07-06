import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs
import qs.services
import qs.modules.samael

// Waybar hyprland/workspaces#kanji — persistent 5, 六…十 when needed (max 10)
// Motion matches waybar/style.css: transition 0.3s cubic-bezier(.55,-0.68,.48,1.682)
Item {
    id: root

    readonly property int persistentCount: 5
    readonly property int maxWorkspace: 10
    readonly property int cellWidth: 22
    readonly property int activePillWidth: 26
    readonly property int capsulePadH: 10

    readonly property var barScreen: root.QsWindow.window?.screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(barScreen)
    readonly property int activeWsId: monitor?.activeWorkspace?.id ?? HyprlandData.activeWorkspace?.id ?? 1

    // Always 1…5; add 6+ only while active or Hyprland still has that workspace
    readonly property int workspaceCount: {
        let high = persistentCount
        const aid = activeWsId
        if (aid > high)
            high = aid
        const values = Hyprland.workspaces.values
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
    // Extra width on the oval only (content stays centered; no Scale)
    property real widthWobble: 0

    implicitWidth: baseCapsuleWidth
    implicitHeight: SamaelStyle.barContentHeight

    onActiveWsIdChanged: widthWobbleAnim.restart()

    // Qt no hace fallback CJK como Pango; cargar DroidSansFallback explícitamente
    FontLoader {
        id: kanjiFontLoader
        source: "file:///usr/share/fonts/droid/DroidSansFallback.ttf"
    }

        SequentialAnimation {
            id: widthWobbleAnim
            NumberAnimation {
                target: root
                property: "widthWobble"
                from: 0
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
            height: 22

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
                    readonly property bool isUrgent: Hyprland.workspaces.values.some(
                        ws => ws.id === wsId && ws.urgent === true)

                        Text {
                            anchors.centerIn: parent
                            text: wsId >= 1 && wsId <= 10 ? root.kanjiLabels[wsId - 1] : String(wsId)
                            color: wsCell.isActive ? WallustColors.workspaceActive
                                  : wsCell.isUrgent ? WallustColors.workspaceUrgent
                                  : hoverMa.containsMouse ? WallustColors.workspaceActive
                                  : WallustColors.workspaceInactive
                            font.pixelSize: SamaelStyle.fontPixelSize
                            font.bold: SamaelStyle.fontBold
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

                    MouseArea {
                        id: hoverMa
                        anchors.fill: parent
                        z: 1
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Hyprland.dispatch("workspace", String(wsCell.wsId))
                    }
                }
            }
        }
    }
}

    MouseArea {
        anchors.fill: parent
        z: -1
        acceptedButtons: Qt.NoButton
        onWheel: (event) => {
            if (event.angleDelta.y > 0)
                Hyprland.dispatch("workspace", "e+1")
            else
                Hyprland.dispatch("workspace", "e-1")
        }
    }
}
