import QtQuick
import "../../components/Icons.js" as Icons

Item {
    id: glyph
    property string name: "logo"
    property color tint: Theme.current.text
    implicitWidth: 20
    implicitHeight: 20
    Image {
        anchors.fill: parent
        source: glyph.name === "logo" ? Qt.resolvedUrl("../../assets/abyssal.svg") : Icons.url(glyph.name, glyph.tint.toString(), 1.6)
        sourceSize: Qt.size(64, 64)
        fillMode: Image.PreserveAspectFit
    }
}
