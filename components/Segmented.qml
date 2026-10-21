import QtQuick
import "../services"

// One-of-N switch: options are [{ value, label, enabled? }].
Rectangle {
    id: root

    property var options: []
    property string value: ""
    property bool uniform: false
    signal picked(string value)

    FontMetrics { id: metrics; font { family: Theme.font; pixelSize: Theme.controlFontSize; bold: true } }
    readonly property real widest: options.reduce((w, o) => Math.max(w, metrics.advanceWidth(o.label) + 22), 0)
    implicitHeight: Theme.controlHeight
    implicitWidth: (uniform ? widest * options.length
        : options.reduce((w, o) => w + metrics.advanceWidth(o.label) + 22, 0)) + Math.max(0, options.length - 1) * 2 + 6
    radius: Theme.trench ? Theme.controlRadius : height / 2
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

                width: root.uniform ? (root.width - 6 - Math.max(0, root.options.length - 1) * 2) / Math.max(1, root.options.length) : metrics.advanceWidth(modelData.label) + 22
                height: Theme.controlHeight - 6
                radius: Theme.trench ? 6 : height / 2
                color: on ? Theme.accentSoft : area.containsMouse && usable ? Theme.hover : "transparent"
                border.width: on ? 1 : 0
                border.color: Theme.alpha(Theme.accent, 0.5)
                opacity: usable ? 1 : 0.35

                Text {
                    id: label
                    anchors.centerIn: parent
                    text: seg.modelData.label
                    color: seg.on ? Theme.accent : Theme.subtext
                    font { family: Theme.font; pixelSize: Theme.controlFontSize; bold: seg.on }
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
