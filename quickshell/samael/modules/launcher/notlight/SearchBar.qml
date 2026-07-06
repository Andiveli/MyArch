import QtQuick
import QtQuick.Controls
import Quickshell

Item {
  required property var backend

  width: parent.width
  height: 60

  function restoreFocus() {
    searchInput.text = ""
    searchInput.forceActiveFocus()
  }

  Image {
    x: 20
    anchors.verticalCenter: parent.verticalCenter
    width: 20
    height: 20
    opacity: 0.85
    source: "data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='20' height='20'%3E%3Ccircle cx='9' cy='9' r='6.5' fill='none' stroke='%2398989d' stroke-width='1.8'/%3E%3Cline x1='14' y1='14' x2='18.5' y2='18.5' stroke='%2398989d' stroke-width='1.8' stroke-linecap='round'/%3E%3C/svg%3E"
  }

  TextInput {
    id: searchInput
    x: 52
    width: parent.width - 116 - modeLabel.width
    anchors.verticalCenter: parent.verticalCenter
    color: backend.textPrimary
    font.family: backend.fontFamily
    font.pixelSize: 21
    font.weight: Font.Normal
    font.letterSpacing: backend.searchLetterSpacing
    selectionColor: backend.accent
    selectByMouse: true
    clip: true

    onTextChanged: backend.processInput(text)

    Text {
      text: backend.placeholderText
      color: backend.textSecondary
      font: searchInput.font
      visible: searchInput.text.length === 0
      anchors.verticalCenter: parent.verticalCenter
      opacity: 0.7
    }

    Keys.onPressed: function(ev) {
      if (ev.key === Qt.Key_Escape) {
        backend.open = false
        ev.accepted = true
      } else if (ev.key === Qt.Key_Down) {
        backend.selectedIndex = Math.min(backend.selectedIndex + 1, backend.results.length - 1)
        ev.accepted = true
      } else if (ev.key === Qt.Key_Up) {
        backend.selectedIndex = Math.max(backend.selectedIndex - 1, 0)
        ev.accepted = true
      } else if (ev.key === Qt.Key_Return || ev.key === Qt.Key_Enter) {
        if (backend.mode === "google") {
          backend.openGoogle(backend.searchQuery)
        } else if (backend.mode === "youtube") {
          if (backend.results.length > 0 && backend.results[backend.selectedIndex]) {
            backend.launch(backend.results[backend.selectedIndex])
          } else if (!backend.searching) {
            backend.runYoutubeSearch()
          }
        } else if (backend.mode === "answer") {
          if (!backend.searching)
            backend.runWebSearch()
        } else if (backend.mode === "web") {
          var sel = backend.results[backend.selectedIndex]
          if (sel && sel.type === "web") {
            Qt.openUrlExternally(sel.url)
            backend.open = false
          } else {
            var code = backend.searchQuery.trim().toLowerCase()
            var url = backend.captures[code]
            if (url) {
              Qt.openUrlExternally(url)
              backend.open = false
            } else if (code.length > 0) {
              backend.answerText = "No URL saved for \"" + code + "\". Add one with /cap <url> <code>"
              backend.answerTitle = ""
              backend.answerUrl = ""
              backend.answerSource = ""
              backend.mode = "answer"
            }
          }
        } else if (backend.mode === "capture" || backend.mode === "shellcap") {
          var text = backend.searchQuery.trim()
          var lastSpace = text.lastIndexOf(" ")
          if (lastSpace > 0) {
            var first = text.slice(0, lastSpace).trim()
            var code = text.slice(lastSpace + 1).trim()
            if (backend.mode === "capture" && first.length > 0 && code.length > 0)
              backend.saveCapture(code, first)
            else if (backend.mode === "shellcap" && first.length > 0 && code.length > 0)
              backend.saveCommand(code, first)
          }
        } else if (backend.mode === "shell") {
          var sel = backend.results[backend.selectedIndex]
          if (sel && sel.type === "shell") {
            Quickshell.execDetached(["kitty", "-e", "/bin/sh", "-c", sel.command])
            backend.open = false
          }
        } else {
          backend.launch(backend.results[backend.selectedIndex])
        }
        ev.accepted = true
      } else if (ev.key === Qt.Key_Backspace && searchInput.text.length === 0) {
        backend.open = false
        ev.accepted = true
      }
    }
  }

  BusyIndicator {
    anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
    width: 16; height: 16
    running: backend.searching
    visible: backend.searching
  }

  Rectangle {
    anchors { right: parent.right; rightMargin: 40; verticalCenter: parent.verticalCenter }
    width: modeLabel.width + 18
    height: 20
    radius: 6
    color: backend.modePillBg
    border.width: 1
    border.color: backend.modePillBorder

    Text {
      id: modeLabel
      anchors.centerIn: parent
      text: backend.modePillText
      color: backend.textSecondary
      font.family: backend.fontFamily
      font.pixelSize: 9
      font.letterSpacing: 0.8
      font.weight: Font.DemiBold
    }
  }
}
