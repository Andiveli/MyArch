pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

/**
 * A nice wrapper for default Pipewire audio sink and source.
 */
Singleton {
    id: root

    // Misc props
    property bool ready: Pipewire.defaultAudioSink?.ready ?? false
    property PwNode sink: Pipewire.defaultAudioSink
    property PwNode source: Pipewire.defaultAudioSource
    readonly property real hardMaxValue: 2.00 // People keep joking about setting volume to 5172% so...
    property string audioTheme: Config.options.sounds.theme
    property real value: sink?.audio.volume ?? 0
    
    function friendlyDeviceName(node) {
        return (node.nickname || node.description || Translation.tr("Unknown"));
    }
    function appNodeDisplayName(node) {
        return (node.properties["application.name"] || node.description || node.name)
    }

    /** Pipewire stream subtitle (page/tab title), same as ii volume mixer. */
    function streamMediaName(node) {
        if (!node)
        return ""
        const media = node.properties["media.name"]
        return media !== undefined && media !== null ? String(media).trim() : ""
    }

    /** Primary line for app audio streams: app • media.name when available. */
    function streamPipewireLabel(node) {
        const app = appNodeDisplayName(node)
        const media = streamMediaName(node)
        return media.length > 0 ? `${app} • ${media}` : app
    }

    // Lists
    function correctType(node, isSink) {
        return (node.isSink === isSink) && node.audio
    }
    function appNodes(isSink) {
        return Pipewire.nodes.values.filter((node) => { // Should be list<PwNode> but it breaks ScriptModel
            return root.correctType(node, isSink) && node.isStream
        })
    }
    function devices(isSink) {
        return Pipewire.nodes.values.filter(node => {
            return root.correctType(node, isSink) && !node.isStream
        })
    }
    readonly property list<var> outputAppNodes: root.appNodes(true)
    readonly property list<var> inputAppNodes: root.appNodes(false)
    readonly property list<var> outputDevices: root.devices(true)
    readonly property list<var> inputDevices: root.devices(false)

    // Signals
    signal sinkProtectionTriggered(string reason);

    // Controls
    function toggleMute() {
        Audio.sink.audio.muted = !Audio.sink.audio.muted
    }

    function toggleMicMute() {
        Audio.source.audio.muted = !Audio.source.audio.muted
    }

    function incrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume = Math.min(1, Audio.sink.audio.volume + step);
    }
    
    function decrementVolume() {
        const currentVolume = Audio.value;
        const step = currentVolume < 0.1 ? 0.01 : 0.02 || 0.2;
        Audio.sink.audio.volume -= step;
    }

    function setDefaultSink(node) {
        Pipewire.preferredDefaultAudioSink = node;
    }

        function setDefaultSource(node) {
            Pipewire.preferredDefaultAudioSource = node;
        }

        /** Move a playback stream to another output device (super menu routing). */
        function moveOutputStreamToSink(streamNode, sinkDeviceNode) {
            if (!streamNode || !sinkDeviceNode)
                return;
            const streamId = streamNode.id;
            const sinkId = sinkDeviceNode.id;
            if (streamId !== undefined && sinkId !== undefined) {
                Quickshell.execDetached(["wpctl", "move-stream", String(streamId), String(sinkId)]);
                return;
            }
            const appName = streamNode.properties["application.name"] || "";
            const mediaName = streamNode.properties["media.name"] || "";
            moveProc.appHint = appName;
            moveProc.mediaHint = mediaName;
            moveProc.sinkName = sinkDeviceNode.name || "";
            moveProc.running = false;
            moveProc.running = true;
        }

        // Internals
        Process {
            id: moveProc
            property string appHint: ""
            property string mediaHint: ""
            property string sinkName: ""
            command: ["pactl", "list", "sink-inputs"]
            stdout: StdioCollector {
                onStreamFinished: {
                    const text = this.text || "";
                    const blocks = text.split(/\nSink Input #/);
                    let targetIdx = "";
                    for (let i = 1; i < blocks.length; i++) {
                        const block = blocks[i];
                        const lines = block.split("\n");
                        const idx = lines[0].trim().split(":")[0].trim();
                        const hay = block.toLowerCase();
                        const appOk = !moveProc.appHint.length || hay.includes(moveProc.appHint.toLowerCase());
                        const mediaOk = !moveProc.mediaHint.length || hay.includes(moveProc.mediaHint.toLowerCase());
                        if (appOk && mediaOk) {
                            targetIdx = idx;
                            break;
                        }
                    }
                    if (targetIdx.length && moveProc.sinkName.length)
                        Quickshell.execDetached(["pactl", "move-sink-input", targetIdx, moveProc.sinkName]);
                }
            }
        }
    PwObjectTracker {
        objects: [sink, source]
    }

    Connections { // Protection against sudden volume changes
        target: sink?.audio ?? null
        property bool lastReady: false
        property real lastVolume: 0
        function onVolumeChanged() {
            if (!Config.options.audio.protection.enable) return;
            const newVolume = sink.audio.volume;
            // when resuming from suspend, we should not write volume to avoid pipewire volume reset issues
            if (isNaN(newVolume) || newVolume === undefined || newVolume === null) {
                lastReady = false;
                lastVolume = 0;
                return;
            }
            if (!lastReady) {
                lastVolume = newVolume;
                lastReady = true;
                return;
            }
            const maxAllowedIncrease = Config.options.audio.protection.maxAllowedIncrease / 100; 
            const maxAllowed = Config.options.audio.protection.maxAllowed / 100;

            if (newVolume - lastVolume > maxAllowedIncrease) {
                sink.audio.volume = lastVolume;
                root.sinkProtectionTriggered(Translation.tr("Illegal increment"));
            } else if (newVolume > maxAllowed || newVolume > root.hardMaxValue) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"));
                sink.audio.volume = Math.min(lastVolume, maxAllowed);
            }
            lastVolume = sink.audio.volume;
        }
    }

    function playSystemSound(soundName) {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`;
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`;

        // Try playing .oga first
        let command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            ogaPath
        ];
        Quickshell.execDetached(command);

        // Also try playing .ogg (ffplay will just fail silently if file doesn't exist)
        command = [
            "ffplay",
            "-nodisp",
            "-autoexit",
            oggPath
        ];
        Quickshell.execDetached(command);
    }
}
