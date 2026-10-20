import QtQuick
import "../services"

// One-of-N switch: options are [{ value, label, enabled? }].
Rectangle {
    id: root

    property var options: []
    property string value: ""
    signal picked(string value)

    implicitHeight: 32
    implicitWidth: row.implicitWidth + 6
    radius: height / 2
    color: Theme.alpha(Theme.crust, 0.6)
    border.width: 1
    border.color: Theme.hairline

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 2

        Repeater {
            model: root.options
            delegate: Rectangle {
                id: seg
                required property var modelData
                readonly property bool on: modelData.value === root.value
                readonly property bool usable: modelData.enabled !== false

                width: label.implicitWidth + 22
                height: 26
                radius: height / 2
                color: on ? Theme.accentSoft : area.containsMouse && usable ? Theme.hover : "transparent"
                border.width: on ? 1 : 0
                border.color: Theme.alpha(Theme.accent, 0.5)
                opacity: usable ? 1 : 0.35

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    color: seg.on ? Theme.accent : Theme.subtext
                    font { family: Theme.font; pixelSize: 11; bold: seg.on }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: seg.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: if (seg.usable && !seg.on) root.picked(seg.modelData.value)
                }
            }
        }
    }
}
