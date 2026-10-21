import QtQuick
import QtQuick.Layouts
import "../services"

// One row in a detail page: icon, title, a detail line, and whatever is
// put inside it on the right (signal bars, battery, buttons). The active
// row (connected network, current output) is tinted cyan.
Rectangle {
    id: root

    property string icon: "square"
    property string title: ""
    property string detail: ""
    property bool active: false
    property color activeColor: Theme.cyan
    default property alias trailing: trail.data
    signal clicked(var mouse)

    Layout.fillWidth: true
    implicitHeight: 44
    radius: 10
    color: area.containsMouse ? Theme.alpha(Theme.text, 0.04) : "transparent"
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    // Below the row's content, so buttons placed on the right get their
    // own clicks.
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: mouse => root.clicked(mouse)
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 10; rightMargin: 10 }
        spacing: 11

        Icon {
            name: root.icon
            size: 15
            stroke: 1.7
            color: root.active ? root.activeColor : Theme.subtext
        }
        ColumnLayout {
            spacing: 0
            Layout.fillWidth: true
            Text {
                text: root.title
                color: Theme.text
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: 12 }
                Layout.fillWidth: true
            }
            Text {
                visible: root.detail !== ""
                text: root.detail
                color: root.active ? Theme.alpha(root.activeColor, 0.8) : Theme.overlay
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: 10 }
                Layout.fillWidth: true
            }
        }
        Row {
            id: trail
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
        }
    }

    // A hovered row shows what its trailing buttons do.
    readonly property bool hovered: area.containsMouse
}
