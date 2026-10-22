import QtQuick
import QtQuick.Controls as C

C.SpinBox {
    id: control
    implicitWidth: 120
    implicitHeight: Math.max(30, contentItem.implicitHeight + 12 * Theme.density)
    font.family: Theme.fontFamily
    font.pixelSize: 12
    leftPadding: 28
    rightPadding: 28
    opacity: enabled ? 1 : 0.5
    contentItem: TextInput {
        text: control.textFromValue(control.value, control.locale)
        font: control.font
        color: Theme.text
        selectionColor: Theme.glowSoft
        selectedTextColor: Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        readOnly: !control.editable
        validator: control.validator
        inputMethodHints: Qt.ImhFormattedNumbersOnly
        selectByMouse: true
    }
    down.indicator: Rectangle {
        width: 26; height: control.height
        radius: Theme.radius
        color: control.down.pressed ? Theme.glowSoft : "transparent"
        Text { anchors.centerIn: parent; text: "−"; color: control.down.enabled ? Theme.glow : Theme.subtext; font.pixelSize: 16 }
    }
    up.indicator: Rectangle {
        x: control.width - width
        width: 26; height: control.height
        radius: Theme.radius
        color: control.up.pressed ? Theme.glowSoft : "transparent"
        Text { anchors.centerIn: parent; text: "+"; color: control.up.enabled ? Theme.glow : Theme.subtext; font.pixelSize: 16 }
    }
    background: Rectangle { color: Theme.deep; radius: Theme.radius; border.color: control.visualFocus ? Theme.glow : Theme.edge; border.width: control.visualFocus ? 2 : 1 }
}
