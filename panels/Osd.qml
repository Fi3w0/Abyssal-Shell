import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// Volume, mic mute and keyboard layout popup at the bottom centre of the
// monitor you are working on. Volume gets a bar; the other two are a
// single line sized to their text.
PanelWindow {
    id: root

    // Passed in from shell.qml: deriving visibility from the window's own
    // `screen` makes a binding loop.
    required property string output
    readonly property bool shown: Shell.osdOutput === output
    readonly property string kind: Shell.osdKind

    readonly property var layout: Tide.keyboardLayout
    readonly property int layoutIndex: layout ? (layout.current_idx || 0) : 0
    readonly property string layoutCode: layout && layout.codes && layout.codes.length > layoutIndex
        ? String(layout.codes[layoutIndex]).toUpperCase() : ""
    readonly property string layoutName: layout && layout.names && layout.names.length > layoutIndex
        ? String(layout.names[layoutIndex]) : ""

    WlrLayershell.namespace: "abyssal-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.bottom: true
    margins.bottom: 48
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: kind === "volume" ? 300 : Math.max(160, line.implicitWidth + 40)
    implicitHeight: 48
    visible: shown || fade.running
    // Never takes input; windows under it stay clickable.
    mask: Region {}

    Rectangle {
        id: pill
        anchors.fill: parent
        radius: height / 2
        color: Theme.glassStrong
        border.width: 1
        border.color: root.kind === "mic" && Shell.osdMuted ? Theme.alpha(Theme.rose, 0.45) : Theme.hairline
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: 180 } }

        RowLayout {
            visible: root.kind === "volume"
            anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
            spacing: 14

            Icon {
                name: Shell.osdMuted || Shell.osdValue === 0 ? "volume-mute" : Shell.osdValue < 0.5 ? "volume-low" : "volume-high"
                size: 17
                color: Shell.osdMuted ? Theme.overlay : Theme.text
            }
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 6
                radius: 3
                color: Theme.alpha(Theme.text, 0.10)
                Rectangle {
                    width: parent.width * (Shell.osdMuted ? 0 : Shell.osdValue)
                    height: parent.height
                    radius: 3
                    color: Theme.accent
                    Behavior on width { NumberAnimation { duration: 90 } }
                }
            }
            Text {
                text: Shell.osdMuted ? "—" : Math.round(Shell.osdValue * 100)
                color: Theme.text
                horizontalAlignment: Text.AlignRight
                font { family: Theme.font; pixelSize: 13; bold: true }
                Layout.preferredWidth: 28
            }
        }

        // Mic: "Microphone muted" / "Microphone on". Layout: "RU  Russian".
        RowLayout {
            id: line
            visible: root.kind !== "volume"
            anchors.centerIn: parent
            spacing: 12

            Icon {
                name: root.kind === "mic" ? (Shell.osdMuted ? "mic-off" : "mic") : "keyboard"
                size: 17
                color: root.kind === "mic" && Shell.osdMuted ? Theme.rose : Theme.text
            }
            Text {
                visible: root.kind === "layout"
                text: root.layoutCode
                color: Theme.accent
                font { family: Theme.monoFont; pixelSize: 13; bold: true }
            }
            Text {
                text: root.kind === "mic" ? (Shell.osdMuted ? "Microphone muted" : "Microphone on") : root.layoutName
                color: root.kind === "mic" && Shell.osdMuted ? Theme.rose : Theme.text
                font { family: Theme.font; pixelSize: 13; bold: root.kind === "mic" }
            }
        }
    }
}
