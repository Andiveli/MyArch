pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string temperature: "--"
    property string description: ""
    property string icon: "cloud"
    property bool available: false

    Timer {
        interval: 600000  // 10 minutos
        running: true
        repeat: true
        onTriggered: fetchWeather.running = true
    }

    Process {
        id: fetchWeather
        running: false
        command: ["bash", "-c", "curl -s 'https://wttr.in/Buenos+Aires?format=%C|%t|%w' 2>/dev/null || echo 'cloud|--|unknown'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = this.text.trim().split("|")
                if (parts.length >= 3) {
                    root.description = parts[0] || ""
                    root.temperature = parts[1] || "--"
                    root.icon = getWeatherIcon(parts[0])
                    root.available = true
                }
            }
        }
    }

    function getWeatherIcon(desc) {
        const d = desc.toLowerCase()
        if (d.includes("sun") || d.includes("clear")) return "☀"
        if (d.includes("cloud")) return "☁"
        if (d.includes("rain") || d.includes("drizzle")) return "🌧"
        if (d.includes("snow")) return "❄"
        if (d.includes("storm") || d.includes("thunder")) return "⛈"
        if (d.includes("fog") || d.includes("mist")) return "🌫"
        return "☁"
    }

    Component.onCompleted: fetchWeather.running = true
}
