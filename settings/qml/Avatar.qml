import QtQuick
import QtQuick.Effects

Rectangle {
    id: root
    property url source
    implicitWidth: 40
    implicitHeight: 40
    radius: Math.min(width, height) * 0.18
    antialiasing: true
    color: Theme.glowSoft
    border.color: Theme.glowEdge
    Image {
        id: image
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        sourceSize: Qt.size(root.width * Screen.devicePixelRatio * 3, root.height * Screen.devicePixelRatio * 3)
        smooth: true
        mipmap: true
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        color: Theme.text
        antialiasing: true
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(width * Screen.devicePixelRatio * 3, height * Screen.devicePixelRatio * 3)
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: image
        maskEnabled: true
        maskSource: mask
        // Preserve the mask's partial alpha instead of thresholding it away.
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
        maskSpreadAtMax: 0.0
        visible: image.status === Image.Ready
    }
}
