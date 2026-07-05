import QtQuick
import Quickshell.Io
import qs.modules.samael
import qs.modules.common.widgets

// Waybar network#speed: min-length 24, "{icon}  {up}  {down}"
Item {
    id: root
    implicitWidth: speedRow.implicitWidth + SamaelStyle.modulePaddingH * 2
    implicitHeight: speedRow.implicitHeight

    property string currentIface: ""
    property var last: ({ rx: 0, tx: 0 })
    property string linkIcon: "󰌙"
    property string upStr: "0B"
    property string downStr: "0B"
    property string tooltipText: ""

    Row {
        id: speedRow
        anchors.centerIn: parent
        spacing: 4

        Text {
            text: root.linkIcon
            color: WallustColors.moduleText
            font.family: SamaelStyle.fontFamily
            font.pixelSize: SamaelStyle.fontPixelSize
            font.bold: SamaelStyle.fontBold
        }

        Text {
            text: " " + root.upStr
            color: WallustColors.moduleText
            font.family: SamaelStyle.fontFamily
            font.pixelSize: SamaelStyle.fontPixelSize
            font.bold: SamaelStyle.fontBold
        }

        Text {
            text: " " + root.downStr
            color: WallustColors.moduleText
            font.family: SamaelStyle.fontFamily
            font.pixelSize: SamaelStyle.fontPixelSize
            font.bold: SamaelStyle.fontBold
        }
    }

    Process {
        id: ifaceProcess
        command: ["bash", "-c", "ip -o route get 1 | sed 's/.* dev //' | awk '{print $1}'"]
        stdout: SplitParser {
            onRead: (data) => {
                root.currentIface = data.trim()
                root.updateLinkIcon()
                readInitialBytes()
            }
        }
        running: true
    }

    function updateLinkIcon() {
        const iface = root.currentIface
        if (!iface.length) {
            root.linkIcon = "󰌙"
            return
        }
        if (iface.startsWith("wl")) {
            root.linkIcon = "󰤨"
            return
        }
        if (iface.startsWith("en") || iface.startsWith("eth")) {
            root.linkIcon = "󰌘"
            return
        }
        root.linkIcon = "󰌘"
    }

    function readInitialBytes() {
        if (!root.currentIface)
            return
        rxFile.reload()
        txFile.reload()
        root.last.rx = parseInt(rxFile.text().trim()) || 0
        root.last.tx = parseInt(txFile.text().trim()) || 0
    }

    FileView { id: rxFile; path: "/sys/class/net/" + root.currentIface + "/statistics/rx_bytes" }
    FileView { id: txFile; path: "/sys/class/net/" + root.currentIface + "/statistics/tx_bytes" }

    function formatSpeed(bytes) {
        if (bytes < 1024)
            return bytes.toFixed(0) + "B"
        if (bytes < 1024 * 1024)
            return (bytes / 1024).toFixed(0) + "K"
        return (bytes / (1024 * 1024)).toFixed(1) + "M"
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateSpeed()
    }

    function updateSpeed() {
        if (!root.currentIface)
            return

        rxFile.reload()
        txFile.reload()

        const rx = parseInt(rxFile.text().trim()) || 0
        const tx = parseInt(txFile.text().trim()) || 0

        const upBytes = Math.max(0, tx - root.last.tx)
        const downBytes = Math.max(0, rx - root.last.rx)

        root.last = { rx: rx, tx: tx }
        root.upStr = formatSpeed(upBytes)
        root.downStr = formatSpeed(downBytes)
    }

    Process {
        id: ipProcess
        command: ["bash", "-c", "ip -o addr show " + root.currentIface + " | awk '/inet /{print $4}' | cut -d/ -f1"]
        stdout: SplitParser {
            onRead: (data) => {
                root.tooltipText = data.trim()
            }
        }
        running: root.currentIface.length > 0
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        StyledToolTip {
            visible: parent.containsMouse
            text: root.tooltipText.length > 0 ? root.tooltipText : root.currentIface
        }
    }
}