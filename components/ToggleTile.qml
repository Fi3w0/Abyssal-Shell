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
    // Shows a › on the right that opens the tile's detail page.
    property bool more: false
    signal toggled()
    signal moreClicked()

    implicitHeight: 60
    radius: Theme.controlRadius
    color: Theme.square ? (on ? Theme.accentSoft : area.containsMouse ? Theme.hover : Theme.surface0)
                       : on ? Theme.alpha(onColor, 0.85) : area.containsMouse ? Theme.alpha(Theme.surface1, 0.95) : Theme.alpha(Theme.surface0, 0.9)
    border.width: 1
    border.color: Theme.square ? (on ? Theme.alpha(onColor, 0.55) : Theme.hairline) : on ? "transparent" : Theme.hairline
    opacity: enabled ? 1 : 0.4
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: root.more ? 40 : 12 }
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
                color: root.on ? (Theme.square ? root.onColor : Theme.crust) : Theme.subtext
            }
        }

        ColumnLayout {
            spacing: 1
            Layout.fillWidth: true
            Text {
                text: root.title
                color: root.on && !Theme.square ? Theme.crust : Theme.text
                font { family: Theme.font; pixelSize: 12; bold: true }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
            Text {
                text: root.detail
                color: Theme.square ? Theme.subtext : root.on ? Theme.alpha(Theme.crust, 0.75) : Theme.overlay
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

    Item {
        visible: root.more
        anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
        width: 36
        Rectangle {
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 1
            height: parent.height - 24
            color: root.on && !Theme.square ? Theme.alpha(Theme.crust, 0.25) : Theme.hairline
        }
        Icon {
            anchors.centerIn: parent
            name: "chevron-right"
            size: 13
            color: root.on && !Theme.square ? Theme.crust : Theme.subtext
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.moreClicked()
        }
    }
}
