import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// "Set position…": every monitor shows its four edges; click one to move
// the selected panel there. Edges with a panel are taken; Esc cancels.
PanelWindow {
    id: root

    // Passed in from shell.qml: deriving visibility from the window's own
    // `screen` makes a binding loop.
    required property string output
    readonly property var used: PanelLayout.panelsFor(output).map(p => p.edge)

    visible: Shell.editing && Shell.pickingPosition && Shell.editTarget !== null
    WlrLayershell.namespace: "abyssal-edit-position"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.crust, 0.55)
        focus: true
        Keys.onEscapePressed: Shell.pickingPosition = false

        MouseArea { anchors.fill: parent; onClicked: Shell.pickingPosition = false }

        Column {
            anchors.centerIn: parent
            spacing: 8
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Click the edge the panel should move to"
                color: Theme.text
                font { family: Theme.font; pixelSize: 18; bold: true }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.output + " · Esc to cancel"
                color: Theme.subtext
                font { family: Theme.font; pixelSize: 12 }
            }
        }

        Repeater {
            model: PanelLayout.edges
            delegate: Rectangle {
                id: target
                required property string modelData
                readonly property bool current: Shell.editTarget !== null && Shell.editTarget.output === root.output
                                                && Shell.editTarget.edge === modelData
                readonly property bool taken: !current && root.used.includes(modelData)
                readonly property bool vertical: modelData === "left" || modelData === "right"

                x: modelData === "left" ? 16 : modelData === "right" ? parent.width - width - 16 : parent.width * 0.15
                y: modelData === "top" ? 16 : modelData === "bottom" ? parent.height - height - 16 : parent.height * 0.18
                width: vertical ? 64 : parent.width * 0.7
                height: vertical ? parent.height * 0.64 : 64
                radius: 18
                color: current ? Theme.alpha(Theme.cyan, 0.35) : taken ? Theme.alpha(Theme.overlay, 0.35)
                     : area.containsMouse ? Theme.alpha(Theme.cyan, 0.22) : Theme.alpha(Theme.cyan, 0.06)
                border.width: 2
                border.color: taken ? "transparent" : Theme.alpha(Theme.cyan, area.containsMouse || current ? 0.95 : 0.45)

                Text {
                    anchors.centerIn: parent
                    rotation: target.vertical ? -90 : 0
                    text: target.current ? "here now" : target.taken ? "taken" : modelData
                    color: target.taken ? Theme.subtext : Theme.cyan
                    font { family: Theme.font; pixelSize: 13; bold: true }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: target.taken || target.current ? Qt.ArrowCursor : Qt.PointingHandCursor
                    onClicked: {
                        if (target.current) Shell.pickingPosition = false
                        else if (!target.taken) Shell.moveTargetTo(root.output, target.modelData)
                    }
                }
            }
        }
    }
}
