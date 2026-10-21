import QtQuick
import QtQuick.Layouts
import "../services"

// Pill button with an optional icon. `accent` fills it violet, `danger`
// tints it for destructive actions.
Item {
    id: root

    property string text: ""
    property string icon: ""
    property bool accent: false
    property bool danger: false
    signal clicked()

    implicitHeight: Theme.controlHeight
    implicitWidth: row.implicitWidth + 24
    opacity: enabled ? 1 : 0.4

    Rectangle {
        anchors.fill: parent
        radius: Theme.trench ? Theme.controlRadius : height / 2
        color: root.accent ? (area.containsMouse ? Qt.lighter(Theme.accent, 1.08) : Theme.accent)
             : area.containsMouse ? Theme.alpha(root.danger ? Theme.danger : Theme.text, 0.12)
             : Theme.alpha(Theme.surface1, 0.8)
        border.width: root.accent ? 0 : 1
        border.color: Theme.controlEdge
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 6
        Icon {
            visible: root.icon !== ""
            name: root.icon
            size: 14
            color: root.accent ? Theme.crust : root.danger ? Theme.danger : Theme.text
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            visible: root.text !== ""
            text: root.text
            color: root.accent ? Theme.crust : root.danger ? Theme.danger : Theme.text
            font { family: Theme.font; pixelSize: Theme.controlFontSize; bold: root.accent }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.clicked()
    }
}
