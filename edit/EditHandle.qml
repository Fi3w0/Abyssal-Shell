import QtQuick
import "../components"
import "../services"

// Edit-mode overlay for one panel item: outline, drag to move, × to
// remove, and a click opens the widget's options when it has any.
Rectangle {
    id: root

    required property var panelRoot
    required property int index
    property string label: ""
    property bool hasOptions: false
    property bool drawOutline: true
    signal optionsRequested()

    radius: 9
    color: drawOutline && area.containsMouse ? Theme.alpha(Theme.cyan, 0.10) : "transparent"
    border.width: drawOutline ? 1 : 0
    border.color: Theme.alpha(Theme.cyan, area.containsMouse ? 0.9 : 0.45)

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        property point pressAt
        property bool dragging: false

        onPressed: mouse => {
            pressAt = Qt.point(mouse.x, mouse.y)
            dragging = false
            root.panelRoot.queueRelayout()
            Shell.selectPanel(root.panelRoot.output, root.panelRoot.edge)
        }
        onPositionChanged: mouse => {
            if (!pressed) return
            if (!dragging && Math.hypot(mouse.x - pressAt.x, mouse.y - pressAt.y) > 4) {
                dragging = true
                root.panelRoot.startDrag(root.index, root.label)
            }
            if (dragging) root.panelRoot.moveDrag(mapToItem(root.panelRoot.contentRoot, mouse.x, mouse.y))
        }
        onReleased: {
            if (dragging) root.panelRoot.finishDrag()
            else if (root.hasOptions) root.optionsRequested()
            dragging = false
        }
    }

    // Options available: a small dot in the opposite corner.
    Rectangle {
        visible: root.hasOptions
        width: 6
        height: 6
        radius: 3
        x: 3
        y: 3
        color: Theme.accent
    }

    Rectangle {
        width: 16
        height: 16
        radius: 8
        x: parent.width - 11
        y: -5
        color: removeArea.containsMouse ? Theme.danger : Theme.surface1
        border.width: 1
        border.color: Theme.alpha(Theme.danger, 0.7)
        Icon {
            anchors.centerIn: parent
            name: "x"
            size: 10
            stroke: 2.6
            color: removeArea.containsMouse ? Theme.crust : Theme.danger
        }
        MouseArea {
            id: removeArea
            anchors.fill: parent
            anchors.margins: -2
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: PanelLayout.removeItem(root.panelRoot.output, root.panelRoot.edge, root.index)
        }
    }
}
