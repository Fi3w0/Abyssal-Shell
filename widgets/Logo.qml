import QtQuick
import "../components"
import "../services"

Item {
    property var ctx

    implicitWidth: ctx && ctx.vertical ? 32 : 36
    implicitHeight: 30

    Icon {
        anchors.centerIn: parent
        name: "logo"
        size: 20
        stroke: 2.2
        color: Theme.cyan
    }
}
