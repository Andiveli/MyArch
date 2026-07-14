import QtQuick
import M3Shapes
import "../singletons"

/** Caelestia CharItem — shape fits inside rowHeight so clip does not eat the anim */
Item {
    id: char

    property int charIndex: 0
    property int rowHeight: 12
    property int shapeKind: MaterialShape.Cookie4Sided
    property real nonAnimWidthScale: 1

    implicitHeight: rowHeight
    implicitWidth: rowHeight * nonAnimWidthScale
    width: implicitWidth
    height: implicitHeight
    clip: false

    MaterialShape {
        id: charShape

        anchors.centerIn: parent
        transformOrigin: Item.Center
        /** Slightly smaller than Caelestia 1.5× so pop/morph stays inside the pill */
        implicitSize: rowHeight * 1.12
        shape: char.shapeKind
        color: WallustColors.foreground
        strokeWidth: 0

        SequentialAnimation {
            id: initAnim
            running: true

            ParallelAnimation {
                NumberAnimation {
                    target: charShape
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: 300
                }
                NumberAnimation {
                    target: charShape
                    property: "scale"
                    from: 0
                    to: 1
                    duration: 140
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.2
                }
                NumberAnimation {
                    target: char
                    property: "implicitWidth"
                    from: rowHeight
                    to: rowHeight * 1.22
                    duration: 300
                }
                PropertyAction {
                    target: char
                    property: "nonAnimWidthScale"
                    value: 1.35
                }
            }
            PauseAnimation { duration: 180 }
            PropertyAction {
                target: charShape
                property: "shape"
                value: MaterialShape.Circle
            }
            ParallelAnimation {
                NumberAnimation {
                    target: charShape
                    property: "scale"
                    to: 2 / 3
                    duration: 140
                }
                NumberAnimation {
                    target: char
                    property: "implicitWidth"
                    to: rowHeight
                    duration: 300
                }
                PropertyAction {
                    target: char
                    property: "nonAnimWidthScale"
                    value: 1
                }
            }
        }
    }
}