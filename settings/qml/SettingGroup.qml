import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Control {
    id: root
    property string title: ""
    property string configSection: ""
    default property alias rows: body.data
    padding: 14 * Theme.density
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    implicitWidth: 380
    Layout.fillWidth: true
    background: Rectangle {
        radius: Theme.groupRadius
        color: Theme.glass
        border.color: Theme.edge
        Repeater {
            model: Theme.corners ? 2 : 0
            Item {
                required property int index
                x: index === 0 ? 0 : parent.width - 12
                y: index === 0 ? 0 : parent.height - 12
                width: 12
                height: 12
                Rectangle { width: 12; height: 2; y: index === 0 ? 0 : 10; color: Theme.glow }
                Rectangle { width: 2; height: 12; x: index === 0 ? 0 : 10; color: Theme.glow }
            }
        }
    }
    contentItem: ColumnLayout {
        spacing: 8
        RowLayout {
            visible: root.title !== ""
            Layout.fillWidth: true
            spacing: 10
            Label { text: root.title.toUpperCase(); color: Theme.glow; font.pixelSize: 11; font.bold: true; font.letterSpacing: 1.5 }
            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.edge }

        }
        ColumnLayout {
            id: body
            Layout.fillWidth: true
            spacing: 0
        }
    }
}
