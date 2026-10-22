import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    property url source
    implicitWidth: 40
    implicitHeight: 40
    radius: Math.min(width, height) * 0.25
    color: Theme.glowSoft
    border.color: Theme.glowEdge
    Image { id: image; anchors.fill: parent; source: root.source; fillMode: Image.PreserveAspectCrop; sourceSize: Qt.size(root.width * 2, root.height * 2); visible: false }
    Rectangle { id: mask; anchors.fill: parent; radius: root.radius; color: Theme.text; layer.enabled: true; visible: false }
    MultiEffect { anchors.fill: parent; source: image; maskEnabled: true; maskSource: mask; visible: image.status === Image.Ready }
}
