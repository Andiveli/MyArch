pragma Singleton
 
import QtQuick
import Quickshell
import Quickshell.Io
import qs
 
Singleton {
    id: root
 
    readonly property string configPath: Quickshell.shellPath("scripts/cava/samael_waybar.conf")
 
    property bool available: true
    property list<double> bars: []
 
    Process {
        id: cavaProcess
        command: ["cava", "-p", root.configPath]
        // Only pay for cava when the bar (main visualizer) or media surfaces that use it are visible
        running: GlobalStates.barOpen || GlobalStates.mediaControlsOpen || GlobalStates.samaelMediaClosing
        stdout: SplitParser {
            onRead: (data) => {
                const trimmed = data.trim()
                if (!trimmed.length)
                    return
                const parts = trimmed.split(";").filter(p => p.length > 0)
                const values = parts.map(p => Math.min(Math.max(parseFloat(p) / 7.0, 0), 1.0))
                root.bars = values
            }
        }
        onExited: () => {
            root.available = false
        }
    }
}
