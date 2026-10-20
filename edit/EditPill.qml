import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// Bottom-centre pill on every monitor while editing: add a panel on a free
// edge, start over from a preset, undo a removed panel, Done.
PanelWindow {
    id: root

    // Passed in from shell.qml: deriving visibility from the window's own
    // `screen` makes a binding loop.
    required property string output
    readonly property var free: PanelLayout.freeEdges(output)
    property bool presetsOpen: false
    readonly property bool undo: Shell.removedPanel !== null && Shell.removedPanel.output === output

    visible: Shell.editing && !Shell.pickingPosition
    WlrLayershell.namespace: "abyssal-edit-pill"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors.bottom: true
    margins.bottom: 16
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: pill.implicitWidth
    implicitHeight: pill.implicitHeight
    onVisibleChanged: presetsOpen = false

    Rectangle {
        id: pill
        anchors.fill: parent
        implicitWidth: row.implicitWidth + 24
        implicitHeight: row.implicitHeight + 16
        radius: 26
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.alpha(Theme.cyan, 0.35)

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: 10

            Rectangle { implicitWidth: 8; implicitHeight: 8; radius: 4; color: Theme.cyan }
            Text {
                text: root.undo ? "Panel removed" : "Editing panels on " + root.output
                color: Theme.text
                font { family: Theme.font; pixelSize: 12 }
            }

            TextButton { visible: root.undo; text: "Undo"; icon: "reboot"; onClicked: Shell.undoRemove() }

            // Add a panel on the first free edge; Set position moves it.
            TextButton {
                visible: !root.undo && !root.presetsOpen && root.free.length > 0
                text: "Add panel"
                icon: "plus"
                onClicked: {
                    const edge = root.free[0]
                    PanelLayout.addPanel(root.output, edge)
                    Shell.selectPanel(root.output, edge)
                }
            }
            TextButton {
                visible: !root.undo && !root.presetsOpen
                text: "Presets…"
                icon: "layout"
                onClicked: root.presetsOpen = true
            }

            // Presets replace this monitor's panels.
            Repeater {
                model: root.presetsOpen ? Object.keys(PanelLayout.presets) : []
                delegate: TextButton {
                    required property string modelData
                    text: PanelLayout.presets[modelData].name
                    onClicked: {
                        PanelLayout.applyPreset(root.output, modelData)
                        const p = PanelLayout.panelsFor(root.output)
                        if (p.length) Shell.selectPanel(root.output, p[0].edge)
                        root.presetsOpen = false
                    }
                }
            }
            TextButton { visible: root.presetsOpen; text: "Cancel"; onClicked: root.presetsOpen = false }

            TextButton { text: "Done"; icon: "check"; accent: true; onClicked: Shell.setEditing(false) }
        }
    }
}
