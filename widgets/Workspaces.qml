import QtQuick
import "../services"

// Pill for the active workspace, dot for occupied, faint dot for empty.
// Shows this monitor's workspaces only.
Item {
    id: root

    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property bool numbers: opts.numbers === true
    readonly property bool vertical: ctx ? ctx.vertical : false
    readonly property var model: Tide.workspacesFor(ctx ? ctx.output : "", opts.minimum ?? 5)

    implicitWidth: pill.width
    implicitHeight: pill.height

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: root.vertical ? 28 : grid.implicitWidth + 18
        height: root.vertical ? grid.implicitHeight + 18 : 28
        radius: Math.min(width, height) / 2
        color: Theme.chip

        Grid {
            id: grid
            anchors.centerIn: parent
            rows: root.vertical ? root.model.length : 1
            columns: root.vertical ? 1 : root.model.length
            spacing: 5

            Repeater {
                model: root.model
                delegate: Item {
                    required property var modelData
                    readonly property bool active: modelData.active

                    implicitWidth: root.numbers ? 24 : root.vertical ? 10 : (active ? 26 : 10)
                    implicitHeight: root.numbers ? 24 : root.vertical ? (active ? 26 : 10) : 10
                    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    Behavior on implicitHeight { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                    Rectangle {
                        anchors.centerIn: parent
                        width: root.numbers ? 22 : root.vertical ? 9 : parent.width
                        height: root.numbers ? 22 : root.vertical ? parent.height : 9
                        radius: 999
                        color: parent.active ? Theme.accent : modelData.occupied ? Theme.subtext : Theme.overlay
                        opacity: parent.active || modelData.occupied ? 1 : 0.5
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.numbers
                        text: modelData.n
                        color: parent.active ? Theme.crust : Theme.text
                        font { family: Theme.font; pixelSize: 11; bold: parent.active }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -3
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Tide.switchWorkspace(root.ctx.output, modelData.n)
                    }
                }
            }
        }
    }
}
