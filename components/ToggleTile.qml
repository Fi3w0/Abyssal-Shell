import QtQuick
import QtQuick.Layouts
import "../services"

// Quick settings tile: icon, title, state line. Violet when on.
Rectangle {
    id: root

    property string icon: "square"
    property string title: ""
    property string detail: ""
    property bool on: false
    property color onColor: Theme.accent
    signal toggled()

    implicitHeight: 60
    radius: 16
    color: on ? Theme.alpha(onColor, 0.85) : area.containsMouse ? Theme.alpha(Theme.surface1, 0.95) : Theme.alpha(Theme.surface0, 0.9)
    border.width: 1
    border.color: on ? "transparent" : Theme.hairline
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 10

        Rectangle {
            implicitWidth: 34
            implicitHeight: 34
            radius: 11
            color: root.on ? Theme.alpha(Theme.crust, 0.18) : Theme.alpha(Theme.crust, 0.5)
            Icon {
                anchors.centerIn: parent
                name: root.icon
                size: 16
                color: root.on ? Theme.crust : Theme.subtext
            }
        }

        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true
            Text {
                text: root.title
                color: root.on ? Theme.crust : Theme.text
                font { family: Theme.font; pixelSize: 12; bold: true }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: root.detail
                color: root.on ? Theme.alpha(Theme.crust, 0.75) : Theme.overlay
                font { family: Theme.font; pixelSize: 10 }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.enabled) root.toggled()
    }
}
