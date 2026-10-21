import QtQuick
import "../services"

// Current XKB layout. Click cycles forward, scroll up/down cycles back and
// forth. Hidden until the compositor answers the `keyboard-layouts` query,
// so an older TideWM shows nothing instead of a dead button.
Item {
    id: root

    property var ctx
    readonly property var layout: Tide.keyboardLayout
    readonly property bool known: layout !== null && layout.names !== undefined
    readonly property int index: known ? (layout.current_idx || 0) : 0
    readonly property var codes: known ? (layout.codes || []) : []
    readonly property var names: known ? (layout.names || []) : []
    readonly property string label: !known ? ""
        : codes.length > index ? String(codes[index]).toUpperCase()
        : names.length > index ? String(names[index]).slice(0, 3).toUpperCase() : "?"

    readonly property bool shown: known

    implicitWidth: 30
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: area.containsMouse ? Theme.hover : "transparent"
    }

    Text {
        anchors.centerIn: parent
        text: root.label
        color: area.containsMouse ? Theme.accent : Theme.subtext
        font { family: Theme.monoFont; pixelSize: 10; bold: true }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Tide.cycleLayout(true)
        onWheel: wheel => Tide.cycleLayout(wheel.angleDelta.y <= 0)
    }
}
