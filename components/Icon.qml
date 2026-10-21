import QtQuick
import "../services"
import "Icons.js" as Icons

// Full-colour brand marks and recolourable line icons. The original wave
// mark remains available as logo-line.
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
        source: root.name === "logo" ? Qt.resolvedUrl("../assets/abyssal.svg")
              : root.name === "undertow" ? Qt.resolvedUrl("../assets/undertow.svg")
              : root.name === "manta" ? Qt.resolvedUrl("../assets/manta.svg")
                                    : Icons.url(root.name === "logo-line" ? "logo" : root.name, root.color.toString(), root.stroke)
        sourceSize.width: Math.ceil(root.size * 2)
        sourceSize.height: Math.ceil(root.size * 2)
        smooth: true
        mipmap: true
    }
}
