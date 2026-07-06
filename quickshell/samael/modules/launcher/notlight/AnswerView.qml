import QtQuick
import Quickshell

Item {
  required property var backend

  width: parent.width
  height: backend.mode === "answer" && backend.answerText.length > 0 ? answerLayout.height + 16 : 0
  visible: backend.mode === "answer" && backend.answerText.length > 0

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: backend.open = false
    z: -1
  }

  Column {
    id: answerLayout
    x: 14
    y: 8
    width: parent.width - 28
    spacing: 4

    Text {
      text: backend.answerTitle
      color: backend.accent
      font.family: backend.fontFamily
      font.pixelSize: 15
      font.weight: Font.DemiBold
      font.letterSpacing: -0.1
      wrapMode: Text.Wrap
      width: parent.width
      visible: backend.answerTitle.length > 0
    }

    Repeater {
      id: answerRepeater
      model: backend.answerSegments
      delegate: Item {
        required property var modelData
        required property int index
        width: answerLayout.width
        height: modelData.type === "code" ? codeBlock.height + 8 : textBlock.height + 4

        Text {
          id: textBlock
          visible: modelData.type === "text"
          text: modelData.content
          color: backend.textPrimary
          font.family: backend.fontFamily
          font.pixelSize: 13
          wrapMode: Text.Wrap
          width: parent.width
          lineHeight: 1.4
          textFormat: Text.MarkdownText
        }

        Rectangle {
          id: codeBlock
          visible: modelData.type === "code"
          width: parent.width
          height: codeText.height + 40
          radius: backend.codeBlockRadius
          color: backend.codeBlockBg
          border.width: 1
          border.color: backend.codeBlockBorder

          Rectangle {
            anchors { top: parent.top; right: parent.right; topMargin: 4; rightMargin: 4 }
            width: langLabel.width + 14
            height: 22
            radius: backend.codeBlockRadius > 8 ? 11 : 0
            color: backend.codeLangBg

            Text {
              id: langLabel
              anchors.centerIn: parent
              text: modelData.lang || "sh"
              color: backend.codeLangText
              font.family: backend.fontFamily
              font.pixelSize: 9
              font.weight: Font.Medium
            }
          }

          Rectangle {
            id: codeCopyBtn
            anchors { top: parent.top; right: parent.right; topMargin: 4; rightMargin: langLabel.width + 24 }
            width: copyLabel.width + 16
            height: 22
            radius: backend.codeBlockRadius > 8 ? 11 : 0
            color: codeCopyArea.containsMouse ? backend.codeCopyBgHover : backend.codeCopyBg
            border.width: 1
            border.color: codeCopyArea.containsMouse ? backend.codeCopyBorderHover : backend.codeCopyBorder

            Text {
              id: copyLabel
              anchors.centerIn: parent
              text: codeBlockItem.copied ? "copied!" : "copy"
              color: codeBlockItem.copied ? backend.codeCopyTextDone : backend.codeCopyText
              font.family: backend.fontFamily
              font.pixelSize: 9
              font.weight: Font.Medium
              font.letterSpacing: 0.5
            }

            MouseArea {
              id: codeCopyArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                Quickshell.execDetached(["wl-copy", "--", codeBlockItem.copyContent])
                codeBlockItem.copied = true
                codeCopyTimer.restart()
              }
            }
          }

          Text {
            id: codeText
            x: 10
            y: 32
            width: parent.width - 20
            text: modelData.content
            color: backend.codeTextColor
            font.family: backend.monoFontFamily
            font.pixelSize: 12
            wrapMode: Text.Wrap
          }

          QtObject {
            id: codeBlockItem
            property string copyContent: modelData.content
            property bool copied: false
          }

          Timer {
            id: codeCopyTimer
            interval: 1500
            onTriggered: codeBlockItem.copied = false
          }
        }
      }
    }

    Item {
      id: sourceRow
      width: parent.width
      height: sourceText.height
      visible: backend.answerSource.length > 0

      Text {
        id: sourceText
        text: "Source: " + backend.answerSource
        color: backend.textSecondary
        font.family: backend.fontFamily
        font.pixelSize: 11
        width: parent.width
        elide: Text.ElideRight
      }
    }
  }
}
