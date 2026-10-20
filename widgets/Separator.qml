import QtQuick
import "../services"

Item {
    property var ctx
    readonly property bool vertical: ctx ? ctx.vertical : false

    implicitWidth: vertical ? 18 : 9
    implicitHeight: vertical ? 9 : 18

    Rectangle {
        anchors.centerIn: parent
        width: parent.vertical ? 16 : 1
        height: parent.vertical ? 1 : 18
        color: Theme.alpha(Theme.text, 0.12)
    }
}
