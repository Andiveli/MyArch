import QtQuick
import QtQuick.Layouts
import "../singletons"

FocusScope {
    id: root

    property bool open: false
    property real morphCloseness: 1

    readonly property var actions: [
        { id: "suspend", icon: "\uf236", run: () => PowerSession.suspend() },
        { id: "poweroff", icon: "\uf011", run: () => PowerSession.poweroff() },
        { id: "logout", icon: "\uf2f5", run: () => PowerSession.logout() },
        { id: "lock", icon: "\uf023", run: () => PowerSession.lock() },
    ]

    property int selectedIndex: 0
    readonly property int columns: 1

    readonly property int cellW: 52
    readonly property int cellH: 48
    readonly property int pad: 10
    readonly property int gap: 6

    implicitWidth: pad * 2 + cellW
    implicitHeight: pad * 2 + cellH * actions.length + gap * (actions.length - 1)

    property real slideT: open ? 0 : 1

    onOpenChanged: {
        if (open) {
            selectedIndex = 0
            slideT = 0
            Qt.callLater(forceActiveFocus)
        } else {
            slideT = 1
        }
    }

    opacity: open ? Math.pow(morphCloseness, 1.2) : 0
    visible: opacity > 0.02
    focus: open
    activeFocusOnTab: false

    function activateAt(i) {
        const a = actions[i]
        if (!a)
            return
        a.run()
        ShellActions.closeRightSurface?.()
    }

    function moveSel(dr, dc) {
        const n = actions.length
        if (n === 0)
            return
        if (dc !== 0)
            return
        selectedIndex = Math.max(0, Math.min(n - 1, selectedIndex + dr))
    }

    Behavior on slideT {
        NumberAnimation {
            duration: Motion.morph
            easing.type: Motion.easeMorph
            easing.bezierCurve: Motion.morphCurve
        }
    }

    Item {
        anchors.fill: parent
        clip: true

        Item {
            id: body
            width: parent.width
            height: parent.height
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.rightMargin: -(root.implicitWidth + 6) * root.slideT

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: pad
                spacing: gap

                Repeater {
                    model: root.actions

                    delegate: Rectangle {
                        required property int index
                        required property var modelData

                        Layout.preferredWidth: root.cellW
                        Layout.preferredHeight: root.cellH
                        radius: 10
                        color: index === root.selectedIndex
                            ? WallustColors.buttonHover
                            : Qt.rgba(0, 0, 0, 0.22)
                        border.width: index === root.selectedIndex ? 2 : 0
                        border.color: WallustColors.workspaceActive

                        Text {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: Style.fontFamily
                            font.pixelSize: 20
                            color: WallustColors.moduleText
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedIndex = index
                                root.activateAt(index)
                            }
                        }
                    }
                }
            }
        }
    }

    Keys.onPressed: event => {
        if (!open)
            return
        if (event.key === Qt.Key_Escape) {
            ShellActions.closeRightSurface?.()
            event.accepted = true
            return
        }
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            activateAt(selectedIndex)
            event.accepted = true
            return
        }
        const t = event.text
        if (t === "j" || event.key === Qt.Key_Down) {
            moveSel(1, 0)
            event.accepted = true
        } else if (t === "k" || event.key === Qt.Key_Up) {
            moveSel(-1, 0)
            event.accepted = true
        }
    }
}