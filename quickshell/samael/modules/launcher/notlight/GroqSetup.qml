import QtQuick

Item {
  required property var backend

  width: parent.width
  height: backend.mode === "answer" && !backend.hasGroqKey && backend.answerText.length === 0 ? setupLayout.height + 16 : 0
  visible: backend.mode === "answer" && !backend.hasGroqKey && backend.answerText.length === 0

  onVisibleChanged: if (visible) groqSetupInput.forceActiveFocus()

  Column {
    id: setupLayout
    x: 14
    y: 8
    width: parent.width - 28
    spacing: 8

    Text {
      text: "Groq API key required"
      color: backend.accent
      font.family: backend.fontFamily
      font.pixelSize: 15
      font.weight: Font.Bold
    }

    Text {
      text: "Enter your Groq API key to use the ASK (/s) mode. Get one for free at console.groq.com"
      color: backend.textSecondary
      font.family: backend.fontFamily
      font.pixelSize: 11
      wrapMode: Text.Wrap
      width: parent.width
    }

    Rectangle {
      width: parent.width
      height: 32
      radius: backend.radiusInner
      color: backend.inputBg
      border.color: backend.dividerColor

      TextInput {
        id: groqSetupInput
        anchors { left: parent.left; leftMargin: 8; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        color: backend.textPrimary
        font.family: backend.fontFamily
        font.pixelSize: 12
        clip: true
        echoMode: TextInput.Password
        text: backend.groqKeyInput
        onTextChanged: backend.groqKeyInput = text
        Keys.onReturnPressed: {
          if (text.trim().length > 0)
            backend.saveGroqKey(text.trim())
        }
        Keys.onEscapePressed: backend.open = false
      }
    }

    Rectangle {
      width: 60
      height: 26
      radius: backend.radiusInner
      color: backend.accent

      Text {
        anchors.centerIn: parent
        text: "Save"
        color: backend.buttonText
        font.family: backend.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (groqSetupInput.text.trim().length > 0)
            backend.saveGroqKey(groqSetupInput.text.trim())
        }
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: backend.open = false
    z: -1
  }
}
