import QtQuick

Item {
  required property var modelData
  required property int index
  required property var backend

  width: ListView.view.width
  height: 56

  readonly property bool isSelected: index === backend.selectedIndex
  readonly property bool isApp: modelData.type === "app"
  readonly property bool isYt: modelData.type === "youtube"
  readonly property bool isShell: modelData.type === "shell"
  readonly property bool isWeb: modelData.type === "web"

  Rectangle {
    anchors.fill: parent
    anchors.leftMargin: 2
    anchors.rightMargin: 2
    radius: backend.radiusInner
    color: isSelected ? backend.accent : "transparent"
  }

  Item {
    x: 16
    width: 32
    height: 32
    anchors.verticalCenter: parent.verticalCenter
    visible: isApp

    Image {
      id: appIcon
      anchors.fill: parent
      source: isApp && modelData.iconPath ? "file://" + modelData.iconPath : ""
      sourceSize { width: 32; height: 32 }
      fillMode: Image.PreserveAspectFit
      asynchronous: true
      visible: status === Image.Ready
    }

    Rectangle {
      anchors.fill: parent
      radius: 0
      color: backend.iconBg
      border.width: 1
      border.color: backend.bevelDarker
      visible: !isApp || !modelData.iconPath || appIcon.status !== Image.Ready

      Text {
        anchors.centerIn: parent
        text: isApp ? modelData.name.charAt(0).toUpperCase() : ""
        color: backend.textPrimary
        font.family: backend.fontFamily
        font.pixelSize: 14
        font.bold: true
      }
    }
  }

  Item {
    x: 16
    width: 32
    height: 32
    anchors.verticalCenter: parent.verticalCenter
    visible: isYt

    Rectangle {
      anchors.fill: parent
      radius: 0
      color: backend.iconBg
      border.width: 1
      border.color: backend.bevelDarker

      Text {
        anchors.centerIn: parent
        text: "\u25B6"
        color: modelData.info.color
        font.pixelSize: 14
      }
    }
  }

  Item {
    x: 16
    width: 32
    height: 32
    anchors.verticalCenter: parent.verticalCenter
    visible: isShell

    Rectangle {
      anchors.fill: parent
      radius: 0
      color: backend.iconBg
      border.width: 1
      border.color: backend.bevelDarker

      Text {
        anchors.centerIn: parent
        text: "$"
        color: modelData.info.color
        font.pixelSize: 16
        font.bold: true
      }
    }
  }

  Item {
    x: 16
    width: 32
    height: 32
    anchors.verticalCenter: parent.verticalCenter
    visible: isWeb

    Rectangle {
      anchors.fill: parent
      radius: 0
      color: backend.iconBg
      border.width: 1
      border.color: backend.bevelDarker

      Text {
        anchors.centerIn: parent
        text: "\u2197"
        color: modelData.info.color
        font.pixelSize: 18
        font.bold: true
      }
    }
  }

  Column {
    x: isApp || isYt || isShell || isWeb ? 54 : 22
    anchors.verticalCenter: parent.verticalCenter
    spacing: 3

    Text {
      text: isShell ? modelData.code : (isWeb ? modelData.code : modelData.name)
      color: isSelected ? backend.textSelected : backend.textPrimary
      font.family: backend.fontFamily
      font.pixelSize: 12
      elide: Text.ElideRight
      width: isApp ? 340 : (isYt ? 380 : (isShell ? 380 : (isWeb ? 380 : 420)))
    }

    Text {
      id: descriptionText
      text: isApp
        ? (modelData.comment || modelData.categories || "")
        : isShell
          ? modelData.command
          : isYt
            ? (modelData.author + "  \u00B7  " + modelData.duration)
            : isWeb
              ? modelData.url
              : modelData.dir + (modelData.ext ? "  \u00B7  " + modelData.ext : "")
      color: isSelected ? backend.descriptionSelectedColor : backend.textSecondary
      font.family: backend.fontFamily
      font.pixelSize: 10
      elide: Text.ElideRight
      width: isApp ? 340 : (isYt ? 380 : (isShell ? 380 : (isWeb ? 380 : 420)))
    }
  }

  Text {
    anchors { right: typePill.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
    text: isApp && modelData.alias ? ":" + modelData.alias : ""
    color: isSelected ? backend.aliasSelectedColor : backend.aliasColor
    font.family: backend.fontFamily
    font.pixelSize: 10
    visible: text.length > 0
  }

  Rectangle {
    id: typePill
    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
    width: catLabel.width + 10
    height: 16
    radius: 0
    color: backend.typePillBg
    border.width: 1
    border.color: backend.typePillBorder
    visible: !isSelected

    Text {
      id: catLabel
      anchors.centerIn: parent
      text: modelData.info.label
      color: modelData.info.color
      font.family: backend.fontFamily
      font.pixelSize: 9
      font.bold: true
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onPositionChanged: backend.selectedIndex = index
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) {
        if (isApp) {
          backend.aliasInputDesktopId = modelData.desktopId
          backend.aliasInputText = modelData.alias || ""
        }
        return
      }
      backend.launch(modelData)
    }
  }
}
