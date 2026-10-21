pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Item {
    id: dock
    property bool labels: false
    RowLayout {
        anchors.fill: parent
        spacing: 12
        Repeater {
            model: Sample.apps
            Controls.Button {
                id: appButton
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                padding: 10
                hoverEnabled: true
                Accessible.name: modelData.name
                background: Rectangle {
                    color: appButton.hovered ? Theme.current.raised : "transparent"
                    radius: Theme.current.radius / 2
                    border.width: appButton.activeFocus ? 1 : 0
                    border.color: Theme.current.accent
                }
                contentItem: RowLayout {
                    spacing: 10
                    Image {
                        source: appButton.modelData.image
                        sourceSize: Qt.size(88, 88)
                        Layout.preferredWidth: 34
                        Layout.preferredHeight: 34
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: Image.PreserveAspectFit
                    }
                    Label {
                        visible: dock.labels
                        text: appButton.modelData.name
                        font.pixelSize: 12
                        Layout.fillWidth: true
                    }
                }
                onClicked: Sample.feedback = "Selected " + modelData.name + " · Preview only"
            }
        }
    }
}
