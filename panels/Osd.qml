import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// Volume popup at the bottom centre of the monitor you are working on.
PanelWindow {
    id: root

    readonly property bool shown: screen && Shell.osdOutput === screen.name

    WlrLayershell.namespace: "abyssal-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.bottom: true
    margins.bottom: 48
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: 300
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
        border.color: Theme.hairline
        opacity: root.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { id: fade; duration: 180 } }

        RowLayout {
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
    }
}
