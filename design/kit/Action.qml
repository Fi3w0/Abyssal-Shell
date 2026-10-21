import QtQuick
import QtQuick.Controls as Controls

Controls.Button {
    id: button
    property bool solid: false
    implicitHeight: 36
    implicitWidth: contentItem.implicitWidth + 24
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 12
    background: Rectangle {
        color: button.solid ? Theme.current.accent : button.checked || button.hovered ? Theme.current.raised : "transparent"
        radius: Theme.current.radius / 2
        border.width: button.activeFocus || button.checked ? 1 : 0
        border.color: Theme.current.accent
    }
    contentItem: Label {
        text: button.text
        font.pixelSize: 13
        color: button.solid ? Theme.current.ink : Theme.current.text
        horizontalAlignment: Text.AlignHCenter
    }
}
