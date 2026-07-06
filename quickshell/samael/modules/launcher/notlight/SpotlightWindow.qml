import QtQuick
import QtQuick.Effects
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland

PanelWindow {
  id: win
  required property var backend

  color: "transparent"
  visible: backend.open
  exclusiveZone: 0
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
  WlrLayershell.namespace: "quickshell:spotlight"
  anchors { top: true; bottom: true; left: true; right: true }

  onVisibleChanged: if (visible) searchBar.restoreFocus()

  MouseArea {
    anchors.fill: parent
    onClicked: backend.open = false
  }

  Item {
    id: panel
    width: 640
    height: Math.min(panelContent.implicitHeight, backend.mode === "answer" ? parent.height - 80 : 660)
    anchors.horizontalCenter: parent.horizontalCenter
    y: Math.round((parent.height - panel.height) / 2)

    opacity: backend.open ? 1 : 0
    scale: backend.open ? 1 : backend.panelScaleClosed
    Behavior on opacity { NumberAnimation { duration: backend.animOpacityDuration; easing.type: backend.animOpacityEasing } }
    Behavior on scale { NumberAnimation { duration: backend.animScaleDuration; easing.type: backend.animScaleEasing } }
    Behavior on height { NumberAnimation { duration: backend.animHeightDuration; easing.type: backend.animHeightEasing } }

    // macOS-style drop shadow
    Rectangle {
      anchors.fill: parent
      anchors.margins: -1
      radius: backend.radius + 1
      color: "transparent"
      visible: backend.hasThemeShadow
      layer.enabled: true
      layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: backend.shadowColor
        shadowBlur: 0.8
        shadowVerticalOffset: 14
        shadowHorizontalOffset: 0
        blurMax: 48
      }
    }

    // Win95 raised outer bevel
    Rectangle {
      anchors.fill: parent
      color: "transparent"
      border.width: 1
      border.color: backend.bevelLight
      z: 2
      visible: backend.hasBevelBorder

      Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: "transparent"
        border.width: 1
        border.color: backend.bevelDarker
      }
    }

    Rectangle {
      id: panelBg
      anchors.fill: parent
      anchors.margins: backend.hasBevelBorder ? 2 : 0
      radius: backend.radius
      color: backend.bgPanel
      border.color: backend.borderColor
      border.width: backend.hasBevelBorder ? 0 : 1
      clip: true

      // subtle top highlight for macOS glassy edge
      Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: parent.height * 0.5
        radius: backend.radius
        visible: !backend.hasBevelBorder
        gradient: Gradient {
          GradientStop { position: 0.0; color: backend.glassHighlight }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }

      MouseArea { anchors.fill: parent }

      Column {
        id: panelContent
        width: parent.width
        spacing: 0
        padding: 0

        // Classic Win95 title bar
        Rectangle {
          width: parent.width
          height: 22
          visible: backend.showTitleBar
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: backend.titleBarGradientFrom }
            GradientStop { position: 1.0; color: backend.titleBarGradientTo }
          }

          Text {
            anchors { left: parent.left; leftMargin: 4; verticalCenter: parent.verticalCenter }
            text: backend.titleBarLabel
            color: backend.titleBarText
            font.family: backend.fontFamily
            font.pixelSize: 12
            font.bold: true
          }

          Rectangle {
            anchors { right: parent.right; rightMargin: 3; verticalCenter: parent.verticalCenter }
            width: 16
            height: 14
            color: backend.bgPanel
            border.width: 1
            border.color: backend.bevelDarker

            Rectangle {
              anchors.fill: parent
              anchors.margins: 1
              color: "transparent"
              border.width: 1
              border.color: backend.bevelLight
            }

            Text {
              anchors.centerIn: parent
              text: "\u2715"
              color: backend.textPrimary
              font.family: backend.fontFamily
              font.pixelSize: 9
              font.bold: true
            }

            MouseArea {
              anchors.fill: parent
              onClicked: backend.open = false
            }
          }
        }

        SearchBar {
          id: searchBar
          backend: win.backend
        }

        Rectangle {
          width: parent.width - 28
          x: 14
          height: 1
          color: backend.dividerColor
          visible: backend.results.length > 0 || (backend.mode === "answer" && (backend.answerText.length > 0 || !backend.hasGroqKey))
        }

        AnswerView {
          backend: win.backend
        }

        GroqSetup {
          backend: win.backend
        }

        ListView {
          id: resultList
          width: parent.width
          height: Math.min(backend.results.length, 8) * 56
          clip: true
          model: backend.results
          currentIndex: backend.selectedIndex
          boundsBehavior: Flickable.StopAtBounds
          interactive: true
          visible: backend.mode === "app" || backend.mode === "file" || backend.mode === "youtube" || backend.mode === "shell" || backend.mode === "web"

          delegate: ResultRow {
            backend: win.backend
          }
        }

        Item {
          id: aliasOverlay
          width: parent.width
          height: backend.aliasInputDesktopId.length > 0 ? 50 : 0
          visible: height > 0
          clip: true

          Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
          }

          Rectangle {
            anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; top: parent.top; topMargin: 4 }
            height: 40
            radius: backend.radiusInner
            color: backend.bgPanel
            border.width: 1
            border.color: backend.bevelDarker

            Rectangle {
              anchors.fill: parent
              anchors.margins: 1
              color: "transparent"
              border.width: 1
              border.color: backend.bevelDark
              visible: backend.hasBevelBorder
            }

            Text {
              anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
              text: backend.aliasSavedFeedback ? "Alias saved!" : "Alias:"
              color: backend.aliasSavedFeedback ? backend.feedbackColor : backend.textSecondary
              font.family: backend.fontFamily
              font.pixelSize: 11
            }

            Rectangle {
              anchors { left: parent.left; leftMargin: 48; right: saveBtn.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
              height: 22
              color: backend.inputBg
              border.width: 1
              border.color: backend.bevelDarker

              Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                color: "transparent"
                border.width: 1
                border.color: backend.bevelDark
                visible: backend.hasBevelBorder
              }

              TextInput {
                id: aliasInput
                anchors { fill: parent; leftMargin: 4; rightMargin: 4 }
                verticalAlignment: TextInput.AlignVCenter
                color: backend.textPrimary
                font.family: backend.fontFamily
                font.pixelSize: 12
                clip: true
                text: backend.aliasInputText
                selectByMouse: true
                maximumLength: 20

                onTextChanged: backend.aliasInputText = text

                Keys.onEscapePressed: {
                  backend.aliasInputDesktopId = ""
                  searchBar.restoreFocus()
                }
                Keys.onReturnPressed: {
                  if (backend.aliasInputText.trim().length > 0) {
                    backend.saveAlias(backend.aliasInputText, backend.aliasInputDesktopId)
                  } else {
                    var existing = backend.aliasForDesktopId(backend.aliasInputDesktopId)
                    if (existing)
                      backend.removeAlias(existing)
                  }
                  backend.aliasInputDesktopId = ""
                  searchBar.restoreFocus()
                }
              }
            }

            Item {
              id: saveBtn
              anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
              width: 24
              height: 22

              Rectangle {
                anchors.fill: parent
                color: backend.surface
                border.width: 1
                border.color: saveArea.pressed ? backend.bevelDarker : backend.bevelLight
                visible: backend.hasBevelBorder

                Rectangle {
                  anchors.fill: parent
                  anchors.margins: 1
                  color: "transparent"
                  border.width: 1
                  border.color: saveArea.pressed ? backend.bevelLight : backend.bevelDarker
                }
              }

              Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: 0
                visible: !backend.hasBevelBorder
              }

              Text {
                anchors.centerIn: parent
                text: "\u2713"
                color: backend.textPrimary
                font.family: backend.fontFamily
                font.pixelSize: 12
              }

              MouseArea {
                id: saveArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                  if (backend.aliasInputText.trim().length > 0) {
                    backend.saveAlias(backend.aliasInputText, backend.aliasInputDesktopId)
                  } else {
                    var existing = backend.aliasForDesktopId(backend.aliasInputDesktopId)
                    if (existing)
                      backend.removeAlias(existing)
                  }
                  backend.aliasInputDesktopId = ""
                  searchBar.restoreFocus()
                }
              }
            }
          }
        }

        Rectangle {
          width: parent.width
          height: backend.captureSavedFeedback ? 36 : 0
          visible: height > 0
          color: "transparent"
          clip: true

          Behavior on height {
            NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
          }

          Text {
            anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }
            text: backend.captureFeedbackText
            color: backend.feedbackColor
            font.family: backend.fontFamily
            font.pixelSize: 12
          }
        }

        Item {
          width: parent.width
          height: backend.results.length > 8 ? 6 : 0
        }
      }
    }
  }

  Connections {
    target: backend
    function onAliasInputDesktopIdChanged() {
      if (backend.aliasInputDesktopId.length > 0) {
        aliasInput.forceActiveFocus()
        aliasInput.selectAll()
      }
    }
  }
}
