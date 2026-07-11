import QtQuick
import Quickshell.Services.Mpris
import "../singletons"

Item {
    id: root
    implicitHeight: Style.barContentHeight
    implicitWidth: label.implicitWidth + 4

    readonly property var players: Mpris.players ? Mpris.players.values : []

    readonly property bool hasMedia: {
        const list = players
        for (let i = 0; i < list.length; i++) {
            const p = list[i]
            if (!p)
                continue
            const name = (p.dbusName || "").toLowerCase()
            if (name.indexOf("playerctld") >= 0)
                continue
            if (p.isPlaying)
                return true
            if (p.trackTitle && String(p.trackTitle).length > 0)
                return true
        }
        return false
    }

    Text {
        id: label
        anchors.verticalCenter: parent.verticalCenter
        text: root.hasMedia ? "\uf001" : "no media"
        color: Colors.moduleText
        font.pixelSize: root.hasMedia ? 13 : 11
        font.family: "JetBrainsMono Nerd Font"
        opacity: root.hasMedia ? 1 : 0.75
    }
}