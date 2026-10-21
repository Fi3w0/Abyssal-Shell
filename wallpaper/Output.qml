import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root
    required property var modelData
    readonly property var screen: Quickshell.screens.find(s => s.name === modelData.output)
    property bool initialized: false
    property string nativeSource: ""
    property string nativeFit: "crop"
    property int nativeSequence: 0
    property string overlaySource: ""
    property string overlayFit: "crop"
    property int overlaySequence: 0
    property real overlayOpacity: 0
    property real overlayStyle: 0
    property bool overlaySuppressed: false
    property string overlayEvent: "overlayReady"

    function url(path) { return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : "" }
    function acknowledge(event, sequence) {
        if (worker.running) worker.write(JSON.stringify({event: event, sequence: sequence}) + "\n")
    }
    onModelDataChanged: if (initialized && worker.running) worker.write(JSON.stringify({config: modelData}) + "\n")
    Component.onCompleted: initialized = true

    Process {
        id: worker
        command: [Quickshell.shellPath("scripts/wallpaper-player"), "run", JSON.stringify(root.modelData)]
        stdinEnabled: true
        running: true
        stdout: SplitParser { onRead: line => {
            try {
                const message = JSON.parse(line)
                if (message.prepare) {
                    fade.stop()
                    root.overlaySequence = message.sequence
                    root.overlayStyle = message.style || 0
                    root.overlayEvent = "overlayReady"
                    root.overlayFit = message.fit
                    root.overlayOpacity = 1
                    root.overlaySource = root.url(message.prepare)
                    if (overlayImage.status === Image.Ready) overlayReady.restart()
                }
                if (message.native !== undefined) {
                    root.nativeSequence = message.sequence
                    root.nativeFit = message.fit || "crop"
                    root.nativeSource = root.url(message.native)
                    if (root.nativeSource && nativeImage.status === Image.Ready) nativeReady.restart()
                }
                if (message.fade) {
                    fade.duration = Math.round(message.duration * 1000)
                    fade.restart()
                }
                if (message.raiseOverlay && root.overlaySource) {
                    // Newly mapped Bottom-layer video surfaces sit above
                    // existing peers. Remap the transition above that video.
                    root.overlayEvent = "raised"
                    root.overlaySuppressed = true
                    remap.restart()
                }
                if (message.error) console.warn("abyssal wallpaper:", message.error)
            } catch (e) { console.warn("abyssal wallpaper message:", e) }
        }}
    }
    Timer { id: nativeReady; interval: 32; onTriggered: root.acknowledge("nativeReady", root.nativeSequence) }
    Timer { id: remap; interval: 1; onTriggered: { root.overlaySuppressed = false; overlayReady.restart() } }
    Timer { id: overlayReady; interval: 32; onTriggered: if (!root.overlaySuppressed) root.acknowledge(root.overlayEvent, root.overlaySequence) }
    NumberAnimation {
        id: fade
        target: root; property: "overlayOpacity"; to: 0
        easing.type: Easing.InOutCubic
        onFinished: root.overlaySource = ""
    }
    PanelWindow {
        id: background
        screen: root.screen
        visible: root.nativeSource !== ""
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "wallpaper-image"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0
        color: "black"
        mask: Region {}
        Image {
            id: nativeImage
            anchors.fill: parent
            source: root.nativeSource
            sourceSize.width: Math.ceil(width * (Screen.devicePixelRatio || 1))
            sourceSize.height: Math.ceil(height * (Screen.devicePixelRatio || 1))
            fillMode: root.nativeFit === "fit" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
            asynchronous: true
            mipmap: true
            onStatusChanged: if (status === Image.Ready) nativeReady.restart()
        }
    }
    PanelWindow {
        screen: root.screen
        visible: root.overlaySource !== "" && !root.overlaySuppressed
        anchors { top: true; bottom: true; left: true; right: true }
        WlrLayershell.namespace: "wallpaper-transition"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}
        Rectangle {
            anchors.fill: parent
            color: "black"
            // Fade the image and its fit-mode bars as one composited frame.
            layer.enabled: true
            visible: overlayImage.status === Image.Ready
            layer.effect: ShaderEffect {
                property variant source
                property real progress: 1 - root.overlayOpacity
                property real effectStyle: root.overlayStyle
                fragmentShader: Qt.resolvedUrl("transition.frag.qsb")
            }
            Image {
                id: overlayImage
                anchors.fill: parent
                source: root.overlaySource
                sourceSize.width: Math.ceil(width * (Screen.devicePixelRatio || 1))
                sourceSize.height: Math.ceil(height * (Screen.devicePixelRatio || 1))
                fillMode: root.overlayFit === "fit" ? Image.PreserveAspectFit : Image.PreserveAspectCrop
                asynchronous: true
                mipmap: true
                onStatusChanged: if (status === Image.Ready) overlayReady.restart()
            }
        }
    }
}
