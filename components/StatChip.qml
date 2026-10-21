import QtQuick
import QtQuick.Layouts
import "../services"

// Icon + small label + value pill (Moonlit's BarMod). On a vertical bar it
// collapses to the icon and shows the value as a tooltip-free compact line.
Item {
    id: root

    property string icon: "square"
    property string label: ""
    property string value: ""
    property color  iconColor: Theme.subtext
    property color  valueColor: Theme.text
    property bool   active: false
    property bool   vertical: false
    property bool   showIcon: true
    signal clicked()

    implicitHeight: vertical ? col.implicitHeight + 12 : 28
    implicitWidth: vertical ? 32 : row.implicitWidth + 22

    Rectangle {
        anchors.fill: parent
        radius: root.vertical ? 9 : height / 2
        color: root.active ? Theme.accentSoft : area.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    RowLayout {
        id: row
        visible: !root.vertical
        anchors.centerIn: parent
        spacing: 5

        Icon { visible: root.showIcon; name: root.icon; size: 15; color: root.iconColor; Layout.alignment: Qt.AlignVCenter }
        Text {
            visible: root.label !== ""
            text: root.label
            color: Theme.overlay
            font { family: Theme.font; pixelSize: 10 }
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            text: root.value
            color: root.active ? Theme.accent : root.valueColor
            font { family: Theme.font; pixelSize: 11; bold: true }
            Layout.alignment: Qt.AlignVCenter
        }
    }

    ColumnLayout {
        id: col
        visible: root.vertical
        anchors.centerIn: parent
        spacing: 2

        Icon { visible: root.showIcon; name: root.icon; size: 15; color: root.iconColor; Layout.alignment: Qt.AlignHCenter }
        Text {
            visible: root.value !== ""
            text: root.value
            color: root.active ? Theme.accent : root.valueColor
            font { family: Theme.font; pixelSize: 9; bold: true }
            elide: Text.ElideRight
            Layout.maximumWidth: 30
            Layout.alignment: Qt.AlignHCenter
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
