import QtQuick
import "../services"
import "Icons.js" as Icons

// One recolourable line icon from Icons.js, rasterised at the screen's real
// pixel density so it stays sharp at fractional scales.
Item {
    id: root

    property string name: "square"
    property color color: Theme.text
    property real size: 16
    property real stroke: 2

    implicitWidth: size
    implicitHeight: size

    Image {
        anchors.fill: parent
        source: Icons.url(root.name, root.color.toString(), root.stroke)
        sourceSize.width: Math.ceil(root.size * 2)
        sourceSize.height: Math.ceil(root.size * 2)
        smooth: true
        mipmap: true
    }
}
