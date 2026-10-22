import QtQuick
import QtQuick.Effects

Item {
    id: root
    property bool active: true
    property bool exposed: true
    property bool resting: false
    readonly property string style: Theme.setting("backgroundStyle", "theme")
    readonly property real shafts: Theme.setting("shafts", 100) / 100
    readonly property real snow: Theme.setting("snow", 80) / 100
    readonly property bool animate: exposed && !resting && !Theme.reduceMotion && Theme.setting("drift", true)
    opacity: Theme.setting("windowOpacity", 100) / 100
    clip: true
    onActiveChanged: {
        if (active) { resting = false; rest.stop(); }
        else rest.restart();
    }
    Timer { id: rest; interval: 10000; onTriggered: root.resting = true }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: root.style === "custom" ? Theme.setting("backgroundTop", Theme.backdropTop) : root.style === "solid" ? Theme.base : Theme.backdropTop }
            GradientStop { position: 0.38; color: root.style === "custom" ? Theme.mix(Qt.color(Theme.setting("backgroundTop", Theme.backdropTop)), Qt.color(Theme.setting("backgroundBottom", Theme.crust)), 0.38) : Theme.base }
            GradientStop { position: 1; color: root.style === "custom" ? Theme.setting("backgroundBottom", Theme.crust) : root.style === "solid" ? Theme.base : Theme.crust }
        }
    }
    Loader {
        anchors.fill: parent
        active: root.style === "wallpaper"
        sourceComponent: Item {
            Image {
                id: wallpaper
                anchors.fill: parent
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: false
                source: {
                    Theme.revision;
                    const screens = Store.value("wallpaper", "screens", {});
                    const entry = screens[Store.outputs()[0]] || screens["*"] || {};
                    return entry.image ? "file://" + entry.image : "";
                }
            }
            MultiEffect { anchors.fill: parent; source: wallpaper; blurEnabled: true; blurMax: 48; blur: 1 }
            Rectangle { anchors.fill: parent; color: Theme.alpha(Theme.crust, 0.55) }
        }
    }
    Item {
        anchors.fill: parent
        opacity: root.shafts
        visible: opacity > 0
        Repeater {
            model: 2
            Rectangle {
                required property int index
                x: parent.width * (index ? 0.8 : 0.5)
                y: -parent.height * 0.6
                width: parent.width * 0.12
                height: parent.height * 1.8
                rotation: 14
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Theme.alpha(Theme.glow, 0) }
                    GradientStop { position: 0.5; color: Theme.alpha(Theme.glow, 0.05) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.glow, 0) }
                }
            }
        }
        SequentialAnimation on opacity {
            running: root.animate && root.shafts > 0
            loops: Animation.Infinite
            NumberAnimation { from: root.shafts * 0.85; to: root.shafts; duration: 6000; easing.type: Easing.InOutSine }
            NumberAnimation { from: root.shafts; to: root.shafts * 0.85; duration: 6000; easing.type: Easing.InOutSine }
        }
    }
    Loader {
        anchors.fill: parent
        active: root.snow > 0
        sourceComponent: Canvas {
            id: snowCanvas
            property real phase: 0
            opacity: root.snow
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: Theme
                function onTextChanged() { snowCanvas.requestPaint(); }
                function onGlowChanged() { snowCanvas.requestPaint(); }
            }
            Timer {
                interval: 33
                running: root.animate
                repeat: true
                onTriggered: { snowCanvas.phase += 0.033; snowCanvas.requestPaint(); }
            }
            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                for (let i = 0; i < 55; i++) {
                    const x = ((i * 127.73) % Math.max(1, width)) + Math.sin(phase * 0.8 + i) * 3;
                    const y = ((i * 83.17) + phase * (6 + i % 9)) % Math.max(1, height);
                    ctx.fillStyle = Theme.alpha(i % 5 ? Theme.text : Theme.glow, 0.2 + (i % 3) * 0.05);
                    ctx.fillRect(x, y, 1 + (i % 3) * 0.4, 1 + (i % 3) * 0.4);
                }
            }
        }
    }
}
