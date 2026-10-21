import QtQuick
import "../services"

Item {
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property int thickness: opts.thickness ?? 1
    readonly property int length: opts.length ?? 18
    readonly property bool vertical: ctx ? ctx.vertical : false

    implicitWidth: vertical ? length : thickness + 8
    implicitHeight: vertical ? thickness + 8 : length

    Rectangle {
        anchors.centerIn: parent
        width: parent.vertical ? parent.length : parent.thickness
        height: parent.vertical ? parent.thickness : parent.length
        color: Theme.alpha(Theme.text, 0.12)
    }
}
