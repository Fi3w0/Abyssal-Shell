import QtQuick

Item {
    id: frame
    property real cut: 14
    property real rounding: 8
    default property alias content: body.data
    Hull {
        x: 2
        y: 5
        width: frame.width
        height: frame.height
        cut: frame.cut
        rounding: frame.rounding
        fill: "#80000000"
        edge: "transparent"
    }
    Hull {
        anchors.fill: parent
        cut: frame.cut
        rounding: frame.rounding
        fill: Theme.current.panel
        lowerFill: Theme.current.panelBottom
        edge: Theme.current.line
    }
    Item {
        id: body
        anchors.fill: parent
    }
}
