import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import "../components"
import "../services"

// Sound through PipeWire: master volume, output device, a volume per app
// that is playing, input device and microphone level.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 2

    readonly property var nodes: Pipewire.nodes.values
    readonly property var outputs: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var inputs: nodes.filter(n => n.audio && !n.isSink && !n.isStream)
    // Playback streams; speech-dispatcher keeps a silent dummy one open.
    readonly property var streams: nodes.filter(n => n.audio && n.isSink && n.isStream
        && !(n.name || "").startsWith("speech-dispatcher"))

    PwObjectTracker { objects: root.active ? root.outputs.concat(root.inputs, root.streams) : [] }

    function label(n) {
        return n.nickname || n.description || n.name
    }
    function appName(n) {
        const p = n.properties || {}
        return p["application.name"] || n.description || n.name
    }
    function deviceIcon(n) {
        return /head(set|phone)/i.test(n.name + " " + n.description) ? "headphones" : "speaker"
    }

    PageHeader {
        icon: "volume-high"
        title: "Sound"
        showBack: root.showBack
        onBack: root.back()
    }

    VolumeLine {
        icon: Audio.muted || Audio.volume === 0 ? "volume-mute" : Audio.volume < 0.5 ? "volume-low" : "volume-high"
        value: Audio.muted ? 0 : Audio.volume
        onIconClicked: Audio.toggleMute()
        onMoved: v => Audio.setVolume(v)
    }

    SectionLabel { text: "Output" }
    Repeater {
        model: root.outputs
        ListRow {
            required property var modelData
            readonly property bool current: Pipewire.defaultAudioSink === modelData
            icon: root.deviceIcon(modelData)
            title: root.label(modelData)
            detail: current ? "In use" : ""
            active: current
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
            Icon {
                opacity: current ? 1 : 0
                anchors.verticalCenter: parent.verticalCenter
                name: "check"
                size: 13
                color: Theme.cyan
            }
        }
    }

    SectionLabel {
        visible: root.streams.length > 0
        text: "Apps"
    }
    Repeater {
        model: root.streams
        VolumeLine {
            required property var modelData
            name: root.appName(modelData)
            icon: modelData.audio && modelData.audio.muted ? "volume-mute" : "volume-high"
            value: modelData.audio ? (modelData.audio.muted ? 0 : modelData.audio.volume) : 0
            onIconClicked: if (modelData.audio) modelData.audio.muted = !modelData.audio.muted
            onMoved: v => { if (modelData.audio) { modelData.audio.muted = false; modelData.audio.volume = v } }
        }
    }

    SectionLabel {
        visible: root.inputs.length > 0
        text: "Input"
    }
    Repeater {
        model: root.inputs
        ListRow {
            required property var modelData
            readonly property bool current: Pipewire.defaultAudioSource === modelData
            icon: "mic"
            title: root.label(modelData)
            active: current
            onClicked: Pipewire.preferredDefaultAudioSource = modelData
            Icon {
                opacity: current ? 1 : 0
                anchors.verticalCenter: parent.verticalCenter
                name: "check"
                size: 13
                color: Theme.cyan
            }
        }
    }
    VolumeLine {
        visible: Audio.source !== null
        icon: Audio.micMuted ? "mic-off" : "mic"
        value: Audio.micMuted ? 0 : Audio.micVolume
        onIconClicked: Audio.toggleMicMute()
        onMoved: v => Audio.setMicVolume(v)
    }

    // Icon (click to mute), optional name, slider, percentage.
    component VolumeLine: RowLayout {
        id: line
        property string icon: "volume-high"
        property string name: ""
        property real value: 0
        signal iconClicked()
        signal moved(real value)

        spacing: 10
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 6
        Layout.topMargin: 4
        Layout.bottomMargin: 4

        BarButton {
            implicitWidth: 26
            implicitHeight: 26
            icon: line.icon
            iconSize: 14
            onClicked: line.iconClicked()
        }
        Text {
            visible: line.name !== ""
            text: line.name
            color: Theme.subtext
            elide: Text.ElideRight
            font { family: Theme.font; pixelSize: 11 }
            Layout.preferredWidth: 86
        }
        Slider {
            Layout.fillWidth: true
            value: line.value
            onMoved: v => line.moved(v)
        }
        Text {
            text: Math.round(line.value * 100)
            color: Theme.overlay
            horizontalAlignment: Text.AlignRight
            font { family: Theme.font; pixelSize: 10 }
            Layout.preferredWidth: 24
        }
    }
}
