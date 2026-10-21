pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// Default speaker and microphone through PipeWire. Any volume or mute
// change, from any app, shows the OSD on the monitor you are working on.
Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false

    readonly property string sinkName: sink ? (sink.description || sink.nickname || sink.name) : "No output"

    PwObjectTracker { objects: [root.sink, root.source].filter(n => n) }

    function setVolume(v) {
        if (sink && sink.audio) {
            sink.audio.muted = false
            sink.audio.volume = Math.max(0, Math.min(1, v))
        }
    }
    function toggleMute() {
        if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
    }
    function setMicVolume(v) {
        if (source && source.audio) source.audio.volume = Math.max(0, Math.min(1, v))
    }
    function toggleMicMute() {
        if (source && source.audio) source.audio.muted = !source.audio.muted
    }

    // Skip the first value after a (re)connect so startup does not flash it.
    property bool _armed: false
    Timer { running: true; interval: 1500; onTriggered: root._armed = true }

    // Read the node itself here: inside its change signal, the `volume` and
    // `muted` bindings above can still hold the old value (the OSD showed
    // "muted" right after unmuting).
    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        function onVolumesChanged() { root.osdFromNode() }
        function onMutedChanged() { root.osdFromNode() }
    }
    Connections {
        target: root.source && root.source.audio ? root.source.audio : null
        function onMutedChanged() {
            if (root._armed) Shell.showOsd("mic", 0, root.source.audio.muted)
        }
    }
    function osdFromNode() {
        if (!_armed || !sink || !sink.audio) return
        Shell.showOsd("volume", sink.audio.volume, sink.audio.muted)
    }
}
