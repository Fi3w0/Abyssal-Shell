import QtQuick
import QtQuick.Effects

Item {
    id: root
    property string symbol
    property color tint: Theme.subtext
    implicitWidth: 15
    implicitHeight: 15
    Image { id: image; anchors.fill: parent; source: "qrc:/icons/" + root.symbol + ".svg"; sourceSize: Qt.size(24, 24); visible: false }
    MultiEffect { anchors.fill: parent; source: image; colorization: 1; colorizationColor: root.tint }
}
